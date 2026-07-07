from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers.admin import router as admin_router
from app.routers.payments import return_router, router
from app.storage.database import init_database


@asynccontextmanager
async def lifespan(_: FastAPI):
	init_database()
	yield


app = FastAPI(
	title="T-Bank Payment Backend",
	description="Backend для универсального подключения T-Bank (Init + PaymentURL)",
	version="1.0.0",
	lifespan=lifespan,
)

app.add_middleware(
	CORSMiddleware,
	allow_origins=["*"],
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)

app.include_router(router)
app.include_router(return_router)
app.include_router(admin_router)


@app.get("/")
async def root() -> dict[str, str]:
	return {
		"service": "tbank-payment-backend",
		"docs": "/docs",
		"health": "/api/payments/health",
		"admin": "/admin",
	}
