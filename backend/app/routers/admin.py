from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import HTMLResponse

from app.config import settings
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
	<title>T-Bank Admin</title>
	<style>
		:root {{
			color-scheme: light dark;
			font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
		}}
		body {{
			margin: 0;
			padding: 24px;
			background: #f5f5f7;
			color: #111;
		}}
		.container {{
			max-width: 1400px;
			margin: 0 auto;
		}}
		h1 {{
			margin: 0 0 8px;
		}}
		.subtitle {{
			color: #666;
			margin-bottom: 20px;
		}}
		.toolbar {{
			display: flex;
			gap: 12px;
			flex-wrap: wrap;
			margin-bottom: 16px;
		}}
		button {{
			border: 0;
			border-radius: 8px;
			padding: 10px 16px;
			background: #ffdd2d;
			color: #111;
			font-weight: 600;
			cursor: pointer;
		}}
		button.secondary {{
			background: #e5e7eb;
		}}
		button:disabled {{
			opacity: 0.6;
			cursor: wait;
		}}
		.status {{
			margin-bottom: 12px;
			min-height: 20px;
			color: #444;
		}}
		table {{
			width: 100%;
			border-collapse: collapse;
			background: #fff;
			border-radius: 12px;
			overflow: hidden;
			box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
		}}
		th, td {{
			padding: 12px 14px;
			border-bottom: 1px solid #ececec;
			text-align: left;
			vertical-align: top;
			font-size: 14px;
		}}
		th {{
			background: #fafafa;
			font-size: 12px;
			text-transform: uppercase;
			letter-spacing: 0.04em;
			color: #666;
		}}
		tr:last-child td {{
			border-bottom: 0;
		}}
		.badge {{
			display: inline-block;
			padding: 4px 8px;
			border-radius: 999px;
			font-size: 12px;
			font-weight: 600;
			background: #eef2ff;
			color: #3730a3;
		}}
		.badge.success {{
			background: #dcfce7;
			color: #166534;
		}}
		.badge.error {{
			background: #fee2e2;
			color: #991b1b;
		}}
		.badge.pending {{
			background: #fef3c7;
			color: #92400e;
		}}
		.mono {{
			font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
			font-size: 12px;
			word-break: break-all;
		}}
		.empty {{
			padding: 32px;
			text-align: center;
			color: #666;
		}}
	</style>
</head>
<body>
	<div class="container">
		<h1>T-Bank Admin</h1>
		<p class="subtitle">Все попытки оплат и актуальные статусы из T-Bank</p>

		<div class="toolbar">
			<button id="refreshListBtn">Обновить список</button>
			<button id="refreshAllBtn" class="secondary">Перезапросить все незавершённые</button>
		</div>

		<div id="status" class="status"></div>

		<table>
			<thead>
				<tr>
					<th>ID</th>
					<th>Order ID</th>
					<th>Payment ID</th>
					<th>Сумма</th>
					<th>Статус</th>
					<th>Return</th>
					<th>Создано</th>
					<th>Обновлено</th>
					<th>Ошибка</th>
					<th></th>
				</tr>
			</thead>
			<tbody id="paymentsBody">
				<tr><td colspan="10" class="empty">Загрузка...</td></tr>
			</tbody>
		</table>
	</div>

	<script>
		const tokenQuery = "{token_query}";
		const statusEl = document.getElementById("status");
		const bodyEl = document.getElementById("paymentsBody");
		const refreshListBtn = document.getElementById("refreshListBtn");
		const refreshAllBtn = document.getElementById("refreshAllBtn");

		function formatAmount(kopecks) {{
			return (kopecks / 100).toFixed(2) + " ₽";
		}}

		function formatDate(value) {{
			if (!value) return "—";
			return new Date(value).toLocaleString("ru-RU");
		}}

		function statusBadge(item) {{
			const status = item.status || "UNKNOWN";
			let className = "badge pending";
			if (item.success) className = "badge success";
			else if (["REJECTED", "INIT_FAILED", "DEADLINE_EXPIRED"].includes(status)) {{
				className = "badge error";
			}}
			return `<span class="${{className}}">${{status}}</span>`;
		}}

		function renderRows(items) {{
			if (!items.length) {{
				bodyEl.innerHTML = '<tr><td colspan="10" class="empty">Попыток оплат пока нет</td></tr>';
				return;
			}}

			bodyEl.innerHTML = items.map((item) => `
				<tr>
					<td>${{item.id}}</td>
					<td class="mono">${{item.order_id || "—"}}</td>
					<td class="mono">${{item.payment_id || "—"}}</td>
					<td>${{formatAmount(item.amount)}}</td>
					<td>${{statusBadge(item)}}</td>
					<td>${{item.return_result || "—"}}</td>
					<td>${{formatDate(item.created_at)}}</td>
					<td>${{formatDate(item.updated_at)}}</td>
					<td>${{item.last_error || "—"}}</td>
					<td>
						<button
							class="secondary"
							data-payment-id="${{item.payment_id || ""}}"
							${{item.payment_id ? "" : "disabled"}}
						>
							Обновить
						</button>
					</td>
				</tr>
			`).join("");

			bodyEl.querySelectorAll("button[data-payment-id]").forEach((button) => {{
				button.addEventListener("click", async () => {{
					const paymentId = button.getAttribute("data-payment-id");
					if (!paymentId) return;
					await refreshPayment(paymentId, button);
				}});
			}});
		}}

		async function apiRequest(path, options = {{}}) {{
			const response = await fetch(`/admin/api${{path}}${{tokenQuery}}`, options);
			if (!response.ok) {{
				const text = await response.text();
				throw new Error(text || `HTTP ${{response.status}}`);
			}}
			return response.json();
		}}

		async function loadPayments() {{
			statusEl.textContent = "Загрузка списка...";
			try {{
				const data = await apiRequest("/payments");
				renderRows(data.items || []);
				statusEl.textContent = `Записей: ${{data.items?.length || 0}}`;
			}} catch (error) {{
				statusEl.textContent = `Ошибка: ${{error.message}}`;
			}}
		}}

		async function refreshPayment(paymentId, button = null) {{
			if (button) {{
				button.disabled = true;
				button.textContent = "...";
			}}
			statusEl.textContent = `Обновление ${{paymentId}}...`;
			try {{
				await apiRequest(`/payments/${{paymentId}}/refresh`, {{ method: "POST" }});
				await loadPayments();
				statusEl.textContent = `Статус ${{paymentId}} обновлён`;
			}} catch (error) {{
				statusEl.textContent = `Ошибка обновления: ${{error.message}}`;
			}} finally {{
				if (button) {{
					button.disabled = false;
					button.textContent = "Обновить";
				}}
			}}
		}}

		async function refreshAllPending() {{
			refreshAllBtn.disabled = true;
			statusEl.textContent = "Перезапрос всех незавершённых платежей...";
			try {{
				const data = await apiRequest("/payments/refresh-all", {{ method: "POST" }});
				renderRows(data.items || []);
				statusEl.textContent = `Обновлено записей: ${{data.updated_count || 0}}`;
			}} catch (error) {{
				statusEl.textContent = `Ошибка: ${{error.message}}`;
			}} finally {{
				refreshAllBtn.disabled = false;
			}}
		}}

		refreshListBtn.addEventListener("click", loadPayments);
		refreshAllBtn.addEventListener("click", refreshAllPending);
		loadPayments();
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
