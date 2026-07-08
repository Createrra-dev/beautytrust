from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import HTMLResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import settings
from app.db import models
from app.db.session import get_db
from app.schemas.api import AdminSupportReplyRequest
from app.services.notification_service import notify_support_reply
from app.services.payment_service import PaymentService

router = APIRouter(prefix="/admin", tags=["admin"])
payment_service = PaymentService()


def verify_admin_access(
	request: Request,
	token: str | None = Query(default=None),
) -> None:
	if not settings.admin_token:
		return

	header_token = request.headers.get("X-Admin-Token")
	provided_token = token or header_token

	if provided_token != settings.admin_token:
		raise HTTPException(status_code=401, detail="Invalid admin token")


@router.get("", response_class=HTMLResponse, dependencies=[Depends(verify_admin_access)])
async def admin_page(token: str | None = Query(default=None)) -> HTMLResponse:
	token_query = f"?token={token}" if token else ""
	html = f"""<!DOCTYPE html>
<html lang="ru">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Beauty Trust Admin</title>
	<style>
		:root {{ color-scheme: light dark; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }}
		body {{ margin: 0; padding: 24px; background: #f5f5f7; color: #111; }}
		.container {{ max-width: 1400px; margin: 0 auto; }}
		h1 {{ margin: 0 0 8px; }}
		.subtitle {{ color: #666; margin-bottom: 16px; }}
		.tabs {{ display: flex; gap: 8px; margin-bottom: 16px; }}
		.tab {{ padding: 8px 14px; border-radius: 8px; background: #e5e7eb; cursor: pointer; border: 0; font-weight: 600; }}
		.tab.active {{ background: #ffdd2d; }}
		.toolbar {{ display: flex; gap: 12px; flex-wrap: wrap; margin-bottom: 16px; }}
		button {{ border: 0; border-radius: 8px; padding: 10px 16px; background: #ffdd2d; color: #111; font-weight: 600; cursor: pointer; }}
		button.secondary {{ background: #e5e7eb; }}
		.status {{ margin-bottom: 12px; min-height: 20px; color: #444; }}
		table {{ width: 100%; border-collapse: collapse; background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,.08); }}
		th, td {{ padding: 12px 14px; border-bottom: 1px solid #ececec; text-align: left; vertical-align: top; font-size: 14px; }}
		th {{ background: #fafafa; font-size: 12px; text-transform: uppercase; letter-spacing: .04em; color: #666; }}
		.mono {{ font-family: ui-monospace, Menlo, monospace; font-size: 12px; word-break: break-all; }}
		.empty {{ padding: 32px; text-align: center; color: #666; }}
		.badge {{ display: inline-block; padding: 4px 8px; border-radius: 999px; font-size: 12px; font-weight: 600; background: #eef2ff; color: #3730a3; }}
		.panel {{ display: none; }}
		.panel.active {{ display: block; }}
		.reply-box {{ display: flex; gap: 8px; margin-top: 8px; }}
		.reply-box input {{ flex: 1; padding: 8px 10px; border-radius: 8px; border: 1px solid #ddd; }}
	</style>
</head>
<body>
	<div class="container">
		<h1>Beauty Trust Admin</h1>
		<p class="subtitle">Платежи и очередь поддержки</p>
		<div class="tabs">
			<button class="tab active" data-tab="payments">Платежи</button>
			<button class="tab" data-tab="tickets">Поддержка</button>
		</div>
		<div id="status" class="status"></div>

		<div id="payments" class="panel active">
			<div class="toolbar">
				<button id="refreshListBtn">Обновить список</button>
				<button id="refreshAllBtn" class="secondary">Перезапросить незавершённые</button>
			</div>
			<table>
				<thead>
					<tr>
						<th>ID</th><th>Order</th><th>Payment</th><th>Сумма</th><th>Статус</th><th>Master</th><th>Plan</th><th></th>
					</tr>
				</thead>
				<tbody id="paymentsBody"><tr><td colspan="8" class="empty">Загрузка...</td></tr></tbody>
			</table>
		</div>

		<div id="tickets" class="panel">
			<div class="toolbar">
				<button id="refreshTicketsBtn">Обновить тикеты</button>
			</div>
			<table>
				<thead>
					<tr>
						<th>ID</th><th>Master</th><th>Заголовок</th><th>Статус</th><th>Последнее</th><th>Ответ</th>
					</tr>
				</thead>
				<tbody id="ticketsBody"><tr><td colspan="6" class="empty">Загрузка...</td></tr></tbody>
			</table>
		</div>
	</div>
	<script>
		const tokenQuery = "{token_query}";
		const statusEl = document.getElementById("status");
		const paymentsBody = document.getElementById("paymentsBody");
		const ticketsBody = document.getElementById("ticketsBody");

		document.querySelectorAll(".tab").forEach((tab) => {{
			tab.addEventListener("click", () => {{
				document.querySelectorAll(".tab").forEach((t) => t.classList.remove("active"));
				document.querySelectorAll(".panel").forEach((p) => p.classList.remove("active"));
				tab.classList.add("active");
				document.getElementById(tab.dataset.tab).classList.add("active");
			}});
		}});

		async function apiRequest(path, options = {{}}) {{
			const response = await fetch(`/admin/api${{path}}${{tokenQuery}}`, options);
			if (!response.ok) throw new Error(await response.text() || `HTTP ${{response.status}}`);
			return response.json();
		}}

		async function loadPayments() {{
			statusEl.textContent = "Загрузка платежей...";
			const data = await apiRequest("/payments");
			const items = data.items || [];
			paymentsBody.innerHTML = items.length ? items.map((item) => `
				<tr>
					<td>${{item.id}}</td>
					<td class="mono">${{item.order_id || "—"}}</td>
					<td class="mono">${{item.payment_id || "—"}}</td>
					<td>${{((item.amount || 0) / 100).toFixed(2)}} ₽</td>
					<td><span class="badge">${{item.status}}</span></td>
					<td>${{item.master_id || "—"}}</td>
					<td>${{item.tariff_plan_id || "—"}}</td>
					<td><button class="secondary" data-pid="${{item.payment_id || ""}}" ${{item.payment_id ? "" : "disabled"}}>Обновить</button></td>
				</tr>`).join("") : '<tr><td colspan="8" class="empty">Пусто</td></tr>';
			paymentsBody.querySelectorAll("button[data-pid]").forEach((btn) => {{
				btn.addEventListener("click", async () => {{
					await apiRequest(`/payments/${{btn.dataset.pid}}/refresh`, {{ method: "POST" }});
					await loadPayments();
				}});
			}});
			statusEl.textContent = `Платежей: ${{items.length}}`;
		}}

		async function loadTickets() {{
			statusEl.textContent = "Загрузка тикетов...";
			const data = await apiRequest("/support/tickets");
			const items = data.items || [];
			ticketsBody.innerHTML = items.length ? items.map((item) => `
				<tr>
					<td class="mono">${{item.id}}</td>
					<td>${{item.author_name}} (#${{item.master_id}})</td>
					<td>${{item.title}}</td>
					<td><span class="badge">${{item.status}}</span></td>
					<td>${{item.last_message || "—"}}</td>
					<td>
						<div class="reply-box">
							<input placeholder="Ответ агента" data-reply="${{item.id}}" />
							<button data-send="${{item.id}}">Отправить</button>
						</div>
					</td>
				</tr>`).join("") : '<tr><td colspan="6" class="empty">Тикетов нет</td></tr>';
			ticketsBody.querySelectorAll("button[data-send]").forEach((btn) => {{
				btn.addEventListener("click", async () => {{
					const id = btn.dataset.send;
					const input = ticketsBody.querySelector(`input[data-reply="${{id}}"]`);
					const text = (input?.value || "").trim();
					if (!text) return;
					await apiRequest(`/support/tickets/${{id}}/reply`, {{
						method: "POST",
						headers: {{ "Content-Type": "application/json" }},
						body: JSON.stringify({{ text }}),
					}});
					await loadTickets();
				}});
			}});
			statusEl.textContent = `Тикетов: ${{items.length}}`;
		}}

		document.getElementById("refreshListBtn").addEventListener("click", () => loadPayments().catch(e => statusEl.textContent = e.message));
		document.getElementById("refreshAllBtn").addEventListener("click", async () => {{
			await apiRequest("/payments/refresh-all", {{ method: "POST" }});
			await loadPayments();
		}});
		document.getElementById("refreshTicketsBtn").addEventListener("click", () => loadTickets().catch(e => statusEl.textContent = e.message));
		loadPayments().catch(e => statusEl.textContent = e.message);
		loadTickets().catch(() => {{}});
	</script>
</body>
</html>"""
	return HTMLResponse(html)


@router.get("/api/payments", dependencies=[Depends(verify_admin_access)])
async def list_payments(limit: int = Query(default=200, ge=1, le=500)) -> dict:
	items = payment_service.repository.list_all(limit=limit)
	return {"items": items, "count": len(items)}


@router.post("/api/payments/{payment_id}/refresh", dependencies=[Depends(verify_admin_access)])
async def refresh_payment(payment_id: str) -> dict:
	try:
		item = await payment_service.refresh_payment_status(payment_id)
	except KeyError as error:
		raise HTTPException(status_code=404, detail=str(error)) from error
	except RuntimeError as error:
		raise HTTPException(status_code=502, detail=str(error)) from error
	except Exception as error:
		raise HTTPException(status_code=502, detail=f"T-Bank request failed: {error}") from error

	return {"item": item}


@router.post("/api/payments/refresh-all", dependencies=[Depends(verify_admin_access)])
async def refresh_all_payments() -> dict:
	items = await payment_service.refresh_all_pending()
	return {"items": items, "updated_count": len(items)}


@router.get("/api/support/tickets", dependencies=[Depends(verify_admin_access)])
async def admin_list_support_tickets(
	limit: int = Query(default=100, ge=1, le=500),
	db: Session = Depends(get_db),
) -> dict:
	tickets = db.scalars(
		select(models.SupportTicket)
		.order_by(models.SupportTicket.last_message_at.desc())
		.limit(limit)
	).all()
	items = [
		{
			"id": ticket.external_id,
			"master_id": ticket.master_id,
			"title": ticket.title,
			"author_name": ticket.author_name,
			"status": ticket.status,
			"last_message": ticket.last_message,
			"last_message_at": ticket.last_message_at.isoformat() if ticket.last_message_at else None,
			"unread_count": ticket.unread_count,
		}
		for ticket in tickets
	]
	return {"items": items, "count": len(items)}


@router.post("/api/support/tickets/{ticket_id}/reply", dependencies=[Depends(verify_admin_access)])
async def admin_reply_support_ticket(
	ticket_id: str,
	body: AdminSupportReplyRequest,
	db: Session = Depends(get_db),
) -> dict:
	ticket = db.scalar(
		select(models.SupportTicket).where(models.SupportTicket.external_id == ticket_id)
	)
	if ticket is None:
		raise HTTPException(status_code=404, detail="Ticket not found")
	if ticket.status in {"closed", "cancelled"}:
		raise HTTPException(status_code=400, detail="Ticket is closed")

	now = datetime.now(timezone.utc)
	text = body.text.strip()
	reply = models.SupportMessage(
		external_id=f"s-admin-{int(now.timestamp())}",
		ticket_id=ticket.id,
		author_name="Техподдержка",
		text=text,
		sent_at=now,
		is_mine=False,
	)
	ticket.last_message = text
	ticket.last_message_at = now
	ticket.status = "in_progress"
	ticket.unread_count += 1
	db.add(reply)
	db.add(ticket)
	db.commit()
	notify_support_reply(db, ticket, text)
	return {"ok": True, "ticket_id": ticket.external_id}
