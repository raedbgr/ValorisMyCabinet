import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime, timedelta

from app.routes.agent import run_agent_check, save_reminders, load_reminders
from app.routes.cabinet import get_client_ids
from uuid import uuid4

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()

async def proactive_agent_job():
    """
    Background job that scans all clients and generates reminders if needed.
    Runs every minute (or 5s for demo purposes).
    """
    logger.info(f"--- Running Proactive Agent Job at {datetime.now()} ---")
    
    client_ids = get_client_ids()
    
    for client_id in client_ids:
        try:
            logger.info(f"Checking client: {client_id}")
            # Run the agent analysis (reads deadlines, scans docs, calls Ollama)
            result = await run_agent_check(client_id)
            
            if result.get("should_remind", False):
                logger.info(f"Agent decided to remind {client_id}: {result.get('urgency')}")
                
                # Create and save reminder — with idempotency check
                all_reminders = load_reminders()

                # Check if we already sent a reminder for this client
                # within the last 6 hours (prevents spamming)
                COOLDOWN_HOURS = 6
                cutoff = (datetime.now() - timedelta(hours=COOLDOWN_HOURS)).isoformat()
                recent = [
                    r for r in all_reminders
                    if r["client_id"] == client_id
                    and r.get("auto", False)
                    and r.get("sent_at", "") > cutoff
                ]

                if recent:
                    logger.info(f"Skipping {client_id} — already reminded {len(recent)} time(s) in last {COOLDOWN_HOURS}h")
                    continue

                reminder = {
                    "id": str(uuid4()),
                    "client_id": client_id,
                    "message": result.get("reminder_message", ""),
                    "urgency": result.get("urgency", "medium"),
                    "sent_at": datetime.now().isoformat(),
                    "auto": True,
                    "channel": "push_notification"
                }

                all_reminders.append(reminder)
                save_reminders(all_reminders)
                logger.info(f"Reminder saved for {client_id}")
                
                # TODO: Trigger Push Notification via Firebase here
                
        except Exception as e:
            logger.error(f"Error processing client {client_id}: {e}")

def start_scheduler():
    """Initialize and start the background scheduler."""
    if not scheduler.running:
        # For demo purposes, we run frequently (every 60 seconds)
        # In a real scenario, this might be once a day
        scheduler.add_job(
            proactive_agent_job,
            trigger=IntervalTrigger(seconds=60),
            id="proactive_agent_scan",
            name="Scan all clients for urgent deadlines",
            replace_existing=True
        )
        scheduler.start()
        logger.info("Proactive Agent Scheduler started.")

def stop_scheduler():
    """Shutdown the scheduler."""
    if scheduler.running:
        scheduler.shutdown()
        logger.info("Proactive Agent Scheduler stopped.")
