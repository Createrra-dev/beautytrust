import logging

from app.config import settings

logger = logging.getLogger(__name__)


def setup_monitoring() -> None:
	if settings.sentry_dsn:
		try:
			import sentry_sdk
			from sentry_sdk.integrations.fastapi import FastApiIntegration
			from sentry_sdk.integrations.starlette import StarletteIntegration

			sentry_sdk.init(
				dsn=settings.sentry_dsn,
				environment=settings.app_env,
				release=settings.app_version,
				traces_sample_rate=settings.sentry_traces_sample_rate,
				integrations=[
					StarletteIntegration(),
					FastApiIntegration(),
				],
			)
			logger.info("Sentry monitoring enabled")
		except Exception as error:
			logger.warning("Sentry init failed: %s", error)
