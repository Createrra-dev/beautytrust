"""telegram auth tables

Revision ID: 0002_telegram_auth
Revises: 0001_initial
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0002_telegram_auth"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column("masters", sa.Column("phone_digits", sa.String(length=10), nullable=True))
	op.add_column("masters", sa.Column("telegram_chat_id", sa.BigInteger(), nullable=True))
	op.create_index("ix_masters_phone_digits", "masters", ["phone_digits"], unique=True)
	op.create_index("ix_masters_telegram_chat_id", "masters", ["telegram_chat_id"], unique=True)

	op.create_table(
		"otp_sessions",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("session_token", sa.String(length=64), nullable=False),
		sa.Column("phone_digits", sa.String(length=10), nullable=False),
		sa.Column("otp_code", sa.String(length=8), nullable=False),
		sa.Column("telegram_chat_id", sa.BigInteger(), nullable=True),
		sa.Column("delivered", sa.Boolean(), nullable=False, server_default=sa.text("false")),
		sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
		sa.Column("verified", sa.Boolean(), nullable=False, server_default=sa.text("false")),
		sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
		sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)
	op.create_index("ix_otp_sessions_session_token", "otp_sessions", ["session_token"], unique=True)
	op.create_index("ix_otp_sessions_phone_digits", "otp_sessions", ["phone_digits"])
	op.create_index("ix_otp_sessions_telegram_chat_id", "otp_sessions", ["telegram_chat_id"])


def downgrade() -> None:
	op.drop_table("otp_sessions")
	op.drop_index("ix_masters_telegram_chat_id", table_name="masters")
	op.drop_index("ix_masters_phone_digits", table_name="masters")
	op.drop_column("masters", "telegram_chat_id")
	op.drop_column("masters", "phone_digits")
