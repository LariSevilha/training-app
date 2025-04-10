class UpdateTrainingsTable < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :trainings, :series
    remove_foreign_key :trainings, :repeats
    remove_foreign_key :trainings, :exercises
    remove_column :trainings, :serie_id, :bigint
    remove_column :trainings, :repeat_id, :bigint
    remove_column :trainings, :exercise_id, :bigint

    # Adicionar os novos campos diretamente
    add_column :trainings, :serie_amount, :string
    add_column :trainings, :repeat_amount, :string
    add_column :trainings, :exercise_name, :string
    add_column :trainings, :video, :string

    # Remover as tabelas series, repeats e exercises, se não forem mais necessárias
    drop_table :series
    drop_table :repeats
    drop_table :exercises
  end
end
