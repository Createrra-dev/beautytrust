"""Profile reviews and settings

Revision ID: 0013_profile_ext
Revises: 0012_prod_infra
Create Date: 2026-07-08
"""

from alembic import op
import sqlalchemy as sa

revision = "0013_profile_ext"
down_revision = "0012_prod_infra"
branch_labels = None
depends_on = None


def upgrade() -> None:
	op.create_table(
		"master_received_reviews",
		sa.Column("id", sa.Integer(), primary_key=True),
		sa.Column("master_id", sa.Integer(), sa.ForeignKey("masters.id"), nullable=False),
		sa.Column("author_name", sa.String(length=120), nullable=False),
		sa.Column("rating", sa.Float(), nullable=False),
		sa.Column("text", sa.Text(), nullable=False),
		sa.Column("review_month", sa.Integer(), nullable=False),
		sa.Column("review_year", sa.Integer(), nullable=False),
		sa.Column(
			"created_at",
			sa.DateTime(timezone=True),
			server_default=sa.text("now()"),
			nullable=False,
		),
	)
	op.create_index(
		"ix_master_received_reviews_master_id",
		"master_received_reviews",
		["master_id"],
	)

	bind = op.get_bind()
	inspector = sa.inspect(bind)
	master_columns = {column["name"] for column in inspector.get_columns("masters")}
	if "settings_json" not in master_columns:
		op.add_column(
			"masters",
			sa.Column("settings_json", sa.Text(), nullable=False, server_default="{}"),
		)

	bind = op.get_bind()
	existing_count = bind.execute(
		sa.text("SELECT COUNT(*) FROM master_received_reviews")
	).scalar()
	if existing_count:
		return

	master_rows = bind.execute(sa.text("SELECT id FROM masters ORDER BY id LIMIT 1")).fetchall()
	if not master_rows:
		return

	master_id = master_rows[0][0]
	seed_reviews = [
		("Екатерина", 5.0, "Отличный мастер, всегда пунктуальна и внимательна к деталям.", 6),
		("Мария", 4.7, "Приятная атмосфера, качественная работа.", 5),
		("Ольга", 4.9, "Рекомендую — профессионал своего дела.", 4),
		("Ирина", 4.5, "Хороший сервис, вернусь снова.", 3),
		("Светлана", 4.8, "Очень довольна результатом.", 2),
	]
	for author, rating, text, month in seed_reviews:
		bind.execute(
			sa.text(
				"""
				INSERT INTO master_received_reviews
				(master_id, author_name, rating, text, review_month, review_year)
				VALUES (:master_id, :author, :rating, :text, :month, 2026)
				"""
			),
			{
				"master_id": master_id,
				"author": author,
				"rating": rating,
				"text": text,
				"month": month,
			},
		)


def downgrade() -> None:
	op.drop_column("masters", "settings_json")
	op.drop_index("ix_master_received_reviews_master_id", table_name="master_received_reviews")
	op.drop_table("master_received_reviews")
