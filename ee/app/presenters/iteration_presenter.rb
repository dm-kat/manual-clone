# frozen_string_literal: true

class IterationPresenter < Gitlab::View::Presenter::Delegated
  presents ::Iteration, as: :iteration

  def iteration_path
    url_builder.build(iteration, only_path: true)
  end

  def iteration_url
    url_builder.build(iteration)
  end

  def scoped_iteration_path(parent:)
    parent_object = find_parent_object(parent)

    if parent_object.is_a?(Project)
      project_iteration_path(parent_object, iteration.id, only_path: true)
    else
      group_iteration_path(parent_object, iteration.id, only_path: true)
    end
  end

  def scoped_iteration_url(parent:)
    parent_object = find_parent_object(parent)

    if parent_object.is_a?(Project)
      project_iteration_url(parent_object, iteration.id)
    else
      group_iteration_url(parent_object, iteration.id)
    end
  end

  private

  def find_parent_object(parent)
    (parent.respond_to?(:context) && parent&.context&.fetch(:parent_object)) ||
      iteration.resource_parent
  end
end
