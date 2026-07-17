"""YClients fail visits on client profiles

Revision ID: 0020_yclients_fail_visits
Revises: 0019_yclients_staff_avatar
Create Date: 2026-07-17
"""

from alembic import op
import sqlalchemy as sa

revision = "0020_yclients_fail_visits"
down_revision = "0019_yclients_staff_avatar"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.add_column(
		"client_profiles",
		sa.Column("yclients_fail_visits_count", sa.Integer(), nullable=False, server_default="0"),
	)


def downgrade() -> None:
	op.drop_column("client_profiles", "yclients_fail_visits_count")
