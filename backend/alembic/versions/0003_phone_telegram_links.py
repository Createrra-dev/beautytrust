"""phone telegram links

Revision ID: 0003_phone_telegram_links
Revises: 0002_telegram_auth
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0003_phone_telegram_links"
down_revision = "0002_telegram_auth"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.create_table(
		"phone_telegram_links",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("phone_digits", sa.String(length=10), nullable=False),
		sa.Column("telegram_chat_id", sa.BigInteger(), nullable=False),
		sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)
	op.create_index(
		"ix_phone_telegram_links_phone_digits",
		"phone_telegram_links",
		["phone_digits"],
		unique=True,
	)
	op.create_index(
		"ix_phone_telegram_links_telegram_chat_id",
		"phone_telegram_links",
		["telegram_chat_id"],
		unique=True,
	)


def downgrade() -> None:
	op.drop_index("ix_phone_telegram_links_telegram_chat_id", table_name="phone_telegram_links")
	op.drop_index("ix_phone_telegram_links_phone_digits", table_name="phone_telegram_links")
	op.drop_table("phone_telegram_links")
