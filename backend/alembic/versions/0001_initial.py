"""initial schema

Revision ID: 0001_initial
Revises:
Create Date: 2026-07-07
"""

from alembic import op
import sqlalchemy as sa

revision = "0001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.create_table(
		"masters",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("first_name", sa.String(length=120), nullable=False),
		sa.Column("badge_label", sa.String(length=120), nullable=False),
		sa.Column("rating", sa.Float(), nullable=False),
		sa.Column("reviews_count", sa.Integer(), nullable=False),
		sa.Column("clients_count", sa.Integer(), nullable=False),
		sa.Column("prevented_no_shows", sa.Integer(), nullable=False),
		sa.Column("protected_income", sa.Integer(), nullable=False),
		sa.Column("tariff_label", sa.String(length=120), nullable=False),
		sa.Column("avatar_path", sa.String(length=500), nullable=True),
		sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)
	op.create_table(
		"master_services",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("name", sa.String(length=200), nullable=False, unique=True),
		sa.Column("duration_label", sa.String(length=50), nullable=False),
		sa.Column("price", sa.Integer(), nullable=False),
	)
	op.create_table(
		"client_profiles",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("phone_digits", sa.String(length=10), nullable=False, unique=True),
		sa.Column("client_name", sa.String(length=120), nullable=False),
		sa.Column("rating_label", sa.String(length=50), nullable=False),
		sa.Column("reviews_average", sa.Float(), nullable=False),
		sa.Column("reviews_count", sa.Integer(), nullable=False),
		sa.Column("no_shows_count", sa.Integer(), nullable=False),
		sa.Column("scandals_count", sa.Integer(), nullable=False),
		sa.Column("reliability_title", sa.String(length=200), nullable=False),
		sa.Column("reliability_subtitle", sa.String(length=200), nullable=False),
	)
	op.create_table(
		"master_reviews",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("client_profile_id", sa.Integer(), sa.ForeignKey("client_profiles.id")),
		sa.Column("author_name", sa.String(length=120), nullable=False),
		sa.Column("rating", sa.Float(), nullable=False),
		sa.Column("text", sa.Text(), nullable=False),
		sa.Column("review_month", sa.Integer(), nullable=False),
		sa.Column("review_year", sa.Integer(), nullable=False),
	)
	op.create_table(
		"appointments",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("external_id", sa.String(length=50), nullable=False, unique=True),
		sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id")),
		sa.Column("client_name", sa.String(length=120), nullable=False),
		sa.Column("client_phone_digits", sa.String(length=10), nullable=False),
		sa.Column("service_name", sa.String(length=200), nullable=False),
		sa.Column("service_duration_label", sa.String(length=50), nullable=False),
		sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False),
		sa.Column("service_price", sa.Integer(), nullable=False),
		sa.Column("client_rating", sa.Float(), nullable=False),
		sa.Column("risk_level", sa.String(length=20), nullable=False),
		sa.Column("days_since_verified", sa.Integer(), nullable=False),
		sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)
	op.create_table(
		"visit_results",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("appointment_id", sa.Integer(), sa.ForeignKey("appointments.id"), unique=True),
		sa.Column("punctuality", sa.String(length=30), nullable=False),
		sa.Column("paid_in_full", sa.Boolean(), nullable=False),
		sa.Column("had_scandal", sa.Boolean(), nullable=False),
		sa.Column("left_tips", sa.Boolean(), nullable=False),
		sa.Column("comment", sa.Text(), nullable=True),
	)
	op.create_table(
		"community_topics",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("external_id", sa.String(length=50), nullable=False, unique=True),
		sa.Column("title", sa.String(length=300), nullable=False),
		sa.Column("author_name", sa.String(length=120), nullable=False),
		sa.Column("emoji", sa.String(length=10), nullable=False),
		sa.Column("is_pinned", sa.Boolean(), nullable=False),
		sa.Column("participant_count", sa.Integer(), nullable=False),
		sa.Column("participant_initials", sa.String(length=100), nullable=False),
		sa.Column("last_message", sa.Text(), nullable=False),
		sa.Column("last_message_at", sa.DateTime(timezone=True), nullable=False),
		sa.Column("unread_count", sa.Integer(), nullable=False),
		sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)
	op.create_table(
		"community_messages",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("external_id", sa.String(length=50), nullable=False, unique=True),
		sa.Column("topic_id", sa.Integer(), sa.ForeignKey("community_topics.id")),
		sa.Column("author_name", sa.String(length=120), nullable=False),
		sa.Column("text", sa.Text(), nullable=False),
		sa.Column("is_mine", sa.Boolean(), nullable=False),
		sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
	)
	op.create_table(
		"support_tickets",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("external_id", sa.String(length=50), nullable=False, unique=True),
		sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id")),
		sa.Column("title", sa.String(length=300), nullable=False),
		sa.Column("author_name", sa.String(length=120), nullable=False),
		sa.Column("status", sa.String(length=30), nullable=False),
		sa.Column("last_message", sa.Text(), nullable=False),
		sa.Column("last_message_at", sa.DateTime(timezone=True), nullable=False),
		sa.Column("unread_count", sa.Integer(), nullable=False),
		sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)
	op.create_table(
		"support_messages",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("external_id", sa.String(length=50), nullable=False, unique=True),
		sa.Column("ticket_id", sa.Integer(), sa.ForeignKey("support_tickets.id")),
		sa.Column("author_name", sa.String(length=120), nullable=False),
		sa.Column("text", sa.Text(), nullable=False),
		sa.Column("is_mine", sa.Boolean(), nullable=False),
		sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
	)
	op.create_table(
		"check_history_records",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("external_id", sa.String(length=50), nullable=False, unique=True),
		sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id")),
		sa.Column("client_name", sa.String(length=120), nullable=False),
		sa.Column("phone_digits", sa.String(length=10), nullable=False),
		sa.Column("rating", sa.Float(), nullable=False),
		sa.Column("risk_level", sa.String(length=20), nullable=False),
		sa.Column("checked_at", sa.DateTime(timezone=True), nullable=False),
	)
	op.create_table(
		"payment_attempts",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("payment_id", sa.String(length=100), nullable=True),
		sa.Column("order_id", sa.String(length=100), nullable=False),
		sa.Column("amount", sa.Integer(), nullable=False),
		sa.Column("description", sa.Text(), nullable=False),
		sa.Column("status", sa.String(length=50), nullable=False),
		sa.Column("success", sa.Boolean(), nullable=False),
		sa.Column("payment_url", sa.Text(), nullable=True),
		sa.Column("return_result", sa.String(length=50), nullable=True),
		sa.Column("last_error", sa.Text(), nullable=True),
		sa.Column("tbank_response", sa.Text(), nullable=True),
		sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
		sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
	)


def downgrade() -> None:
	op.drop_table("payment_attempts")
	op.drop_table("check_history_records")
	op.drop_table("support_messages")
	op.drop_table("support_tickets")
	op.drop_table("community_messages")
	op.drop_table("community_topics")
	op.drop_table("visit_results")
	op.drop_table("appointments")
	op.drop_table("master_reviews")
	op.drop_table("client_profiles")
	op.drop_table("master_services")
	op.drop_table("masters")
