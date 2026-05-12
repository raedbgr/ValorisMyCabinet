import json
import re

import httpx
from app.config import settings


class OllamaService:
    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.model = settings.OLLAMA_MODEL

    async def chat(self, messages: list[dict], system_prompt: str = None) -> str:
        """
        Send a chat request to Ollama.
        If system_prompt is provided, it is prepended as a system message.
        """
        chat_messages = list(messages)

        if system_prompt:
            chat_messages.insert(0, {"role": "system", "content": system_prompt})

        url = f"{self.base_url}/api/chat"
        payload = {
            "model": self.model,
            "messages": chat_messages,
            "stream": False
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, json=payload, timeout=60.0)
                response.raise_for_status()
                return response.json()["message"]["content"]
        except Exception:
            return "Ollama service is not available. Make sure it is running on localhost."

    async def is_alive(self) -> bool:
        """
        Check if Ollama is reachable by calling GET /api/tags.
        """
        url = f"{self.base_url}/api/tags"

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, timeout=5.0)
                return response.status_code == 200
        except Exception:
            return False

    async def analyze_and_remind(
        self,
        client_name: str,
        deadlines: list[dict],
        missing_documents: list[dict]
    ) -> dict:
        """
        Run an iterative tool‑calling loop.
        The LLM receives a system prompt that describes the 5 available tools
        (list_documents, get_upcoming_deadlines, get_missing_documents,
        request_document, get_client_status) and is asked to either:
            * call a tool (by returning {"tool": "name", "args": {...}})
            * or return the final reminder payload under "final".
        The loop runs up to MAX_ITERATIONS (5) to avoid runaway calls.
        """
        import json
        from app.services.tools import TOOLS_REGISTRY

        MAX_ITERATIONS = 5
        # Base system prompt describing the assistant role and tool usage
        system_prompt = (
            "Tu es un agent comptable proactif pour le cabinet Valoris en Tunisie. "
            "Tu ne discutes QUE des obligations fiscales, documents et echeances de ce client specifique. "
            "Si on te pose une question hors sujet, reponds poliment que tu ne peux pas aider avec ca. "
            "Tu peux appeler les outils suivants en renvoyant un JSON strict : "
            "{\"tool\": \"tool_name\", \"args\": {...}}. "
            "Si tu as toutes les informations necessaires, renvoie le resultat final sous la cle "
            "\"final\" avec cette structure: {\"should_remind\": bool, \"reminder_message\": str, \"urgency\": str, \"missing_docs_summary\": str}. "
            "IMPORTANT - Citations: quand tu mentionnes un document specifique dans ton message, "
            "utilise le format [doc:nom_du_fichier] pour que le frontend puisse le rendre cliquable. "
            "Exemple: 'Votre [doc:facture_juillet.pdf] a bien ete recu.' "
            "Ne retourne jamais d'autres champs. "
            "Les outils disponibles sont :\n"
        )
        # Append a short description of each tool for the model
        tool_descriptions = {
            "list_documents": "Lister les documents d'un client, optionnellement filtres par categorie.",
            "get_upcoming_deadlines": "Obtenir les echeances a venir (urgent/late) d'un client.",
            "get_missing_documents": "Lister les documents attendus mais manquants pour un type d'echeance.",
            "request_document": "Creer une demande de document et la sauvegarder dans reminders.json.",
            "get_client_status": "Obtenir un resume du statut du client (deadlines, docs, % complet).",
            "mark_document_received": "Marque un document specifique comme recu/verifie pour un client. Utilise cet outil uniquement quand tu confirmes qu'un document manquant a bien ete fourni."
        }
        for name, desc in tool_descriptions.items():
            system_prompt += f"- {name}: {desc}\n"
        system_prompt += "Utilise ces outils si besoin pour construire le rappel."

        # Initialise la conversation avec les données fournies
        messages = [
            {"role": "user", "content": f"Client: {client_name}\n\nÉchéances: {json.dumps(deadlines, ensure_ascii=False)}\n\nDocuments manquants: {json.dumps(missing_documents, ensure_ascii=False)}"}
        ]

        for iteration in range(MAX_ITERATIONS):
            # Send the current messages + system prompt to Ollama
            raw = await self.chat(messages, system_prompt)

            # Try to extract a JSON block from the response
            response_json = None
            try:
                json_match = re.search(r"\{.*\}", raw, re.DOTALL)
                if not json_match:
                    raise ValueError("No JSON found")
                response_json = json.loads(json_match.group())
            except Exception:
                # RETRY ONCE: send a correction prompt
                correction = (
                    "Ta reponse n'etait pas un JSON valide. "
                    "Re-essaie en respectant strictement le format: "
                    "{\"tool\": \"name\", \"args\": {...}} ou "
                    "{\"final\": {\"should_remind\": ..., \"reminder_message\": ..., \"urgency\": ..., \"missing_docs_summary\": ...}}"
                )
                messages.append({"role": "user", "content": correction})
                raw_retry = await self.chat(messages, system_prompt)

                try:
                    json_match = re.search(r"\{.*\}", raw_retry, re.DOTALL)
                    if not json_match:
                        raise ValueError("No JSON found on retry")
                    response_json = json.loads(json_match.group())
                except Exception:
                    # Both attempts failed — give up and use fallback
                    break

            # If the model returns a final payload, we're done
            if "final" in response_json:
                return response_json["final"]

            # Otherwise expect a tool call
            tool_name = response_json.get("tool")
            args = response_json.get("args", {})
            if not tool_name or tool_name not in TOOLS_REGISTRY:
                # Invalid tool request – stop the loop
                break

            # Execute the tool
            tool_result = TOOLS_REGISTRY[tool_name](args)

            # Append the tool result as a new assistant message so the model can reason further
            messages.append({
                "role": "assistant",
                "content": f"Tool {tool_name} returned: {json.dumps(tool_result, ensure_ascii=False)}"
            })

        # Fallback response if loop ends without a final answer
        return {
            "should_remind": True,
            "reminder_message": f"Bonjour {client_name}, vous avez des échéances fiscales à venir. Merci de nous transmettre les documents manquants.",
            "urgency": "medium",
            "missing_docs_summary": "Documents non analysés"
        }


ollama_service = OllamaService()
