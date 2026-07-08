"""master email/password and registration draft on otp session

Revision ID: 0006_master_registration_fields
Revises: 0005_otp_zvonok_call_id
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0006_master_registration_fields"
down_revision = "0005_otp_zvonok_call_id"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column("masters", sa.Column("email", sa.String(length=255), nullable=True))
	op.add_column("masters", sa.Column("password_hash", sa.String(length=255), nullable=True))
	op.create_index("ix_masters_email", "masters", ["email"], unique=True)

	op.add_column("otp_sessions", sa.Column("registration_first_name", sa.String(length=120), nullable=True))
	op.add_column("otp_sessions", sa.Column("registration_email", sa.String(length=255), nullable=True))
	op.add_column(
		"otp_sessions",
		sa.Column("registration_password_hash", sa.String(length=255), nullable=True),
	)


def downgrade() -> None:
	op.drop_column("otp_sessions", "registration_password_hash")
	op.drop_column("otp_sessions", "registration_email")
	op.drop_column("otp_sessions", "registration_first_name")
	op.drop_index("ix_masters_email", table_name="masters")
	op.drop_column("masters", "password_hash")
	op.drop_column("masters", "email")
