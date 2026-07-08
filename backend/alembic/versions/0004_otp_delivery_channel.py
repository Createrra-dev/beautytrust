"""otp delivery channel

Revision ID: 0004_otp_delivery_channel
Revises: 0003_phone_telegram_links
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0004_otp_delivery_channel"
down_revision = "0003_phone_telegram_links"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"otp_sessions",
		sa.Column(
			"delivery_channel",
			sa.String(length=20),
			nullable=False,
			server_default="telegram",
		),
	)


def downgrade() -> None:
	op.drop_column("otp_sessions", "delivery_channel")
