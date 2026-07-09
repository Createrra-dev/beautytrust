"""YClients staff avatar fields

Revision ID: 0019_yclients_staff_avatar
Revises: 0018_yclients_sync_interval
Create Date: 2026-07-09
"""

from alembic import op
import sqlalchemy as sa

revision = "0019_yclients_staff_avatar"
down_revision = "0018_yclients_sync_interval"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"appointments",
		sa.Column("yclients_staff_avatar_path", sa.String(500), nullable=True),
	)
	op.add_column(
		"appointments",
		sa.Column("yclients_staff_avatar_source_url", sa.String(500), nullable=True),
	)


def downgrade() -> None:
	op.drop_column("appointments", "yclients_staff_avatar_source_url")
	op.drop_column("appointments", "yclients_staff_avatar_path")
