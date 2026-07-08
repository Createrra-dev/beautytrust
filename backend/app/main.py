from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path

from app.config import settings
from app.db.base import Base
from app.db.seed import seed_database
from app.db.session import SessionLocal, engine
from app.routers.admin import router as admin_router
from app.routers.auth import router as auth_router
from app.routers.mobile import router as mobile_router
from app.routers.payments import return_router, router as payments_router
from app.services.telegram_bot import setup_webhook
from app.storage.database import init_database


@asynccontextmanager
async def lifespan(_: FastAPI):
	init_database()
	Base.metadata.create_all(bind=engine)
	with SessionLocal() as db:
		seed_database(db)

	uploads_path = Path(settings.uploads_dir)
	if not uploads_path.is_absolute():
		uploads_path = Path(__file__).resolve().parents[1] / uploads_path
	uploads_path.mkdir(parents=True, exist_ok=True)
	await setup_webhook()
	yield


app = FastAPI(
	title="Beauty Trust API",
	description="Backend для мобильного приложения Beauty Trust",
	version="2.0.0",
	lifespan=lifespan,
)

app.add_middleware(
	CORSMiddleware,
	allow_origins=settings.cors_origin_list,
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)

app.include_router(payments_router)
app.include_router(return_router)
app.include_router(admin_router)
app.include_router(auth_router)
app.include_router(mobile_router)

uploads_dir = Path(settings.uploads_dir)
if not uploads_dir.is_absolute():
	uploads_dir = Path(__file__).resolve().parents[1] / uploads_dir
uploads_dir.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(uploads_dir)), name="uploads")


@app.get("/")
async def root() -> dict[str, str]:
	return {
		"service": "beautytrust-api",
		"docs": "/docs",
		"health": "/api/health",
		"payments_health": "/api/payments/health",
	}
