"""zvonok call id on otp session

Revision ID: 0005_otp_zvonok_call_id
Revises: 0004_otp_delivery_channel
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0005_otp_zvonok_call_id"
down_revision = "0004_otp_delivery_channel"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column("otp_sessions", sa.Column("zvonok_call_id", sa.BigInteger(), nullable=True))


def downgrade() -> None:
	op.drop_column("otp_sessions", "zvonok_call_id")
