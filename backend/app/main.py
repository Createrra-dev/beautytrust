from contextlib import asynccontextmanager
import logging
from pathlib import Path

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException
from fastapi import HTTPException

from app.config import settings
from app.core.errors import (
	ApiError,
	api_error_handler,
	http_exception_handler,
	starlette_http_exception_handler,
	unhandled_exception_handler,
	validation_exception_handler,
)
from app.db.base import Base
from app.db.seed import seed_database
from app.db.session import SessionLocal, engine
from app.middleware.request_logging import RequestLoggingMiddleware
from app.routers.admin import router as admin_router
from app.routers.auth import router as auth_router
from app.routers.mobile import router as mobile_router
from app.routers.payments import return_router, router as payments_router
from app.services.telegram_bot import setup_webhook

logging.basicConfig(
	level=logging.INFO,
	format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)


@asynccontextmanager
async def lifespan(_: FastAPI):
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

app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(
	CORSMiddleware,
	allow_origins=settings.cors_origin_list,
	allow_credentials=True,
	allow_methods=["*"],
	allow_headers=["*"],
)

app.add_exception_handler(ApiError, api_error_handler)
app.add_exception_handler(HTTPException, http_exception_handler)
app.add_exception_handler(StarletteHTTPException, starlette_http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, unhandled_exception_handler)

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
