# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::WeightService::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:work_item) { create(:work_item, project: project, author: user, weight: 1) }

  let(:widget) { work_item.widgets.find {|widget| widget.is_a?(WorkItems::Widgets::Weight) } }

  describe '#update' do
    subject { described_class.new(widget: widget, current_user: user).update(params: params) } # rubocop:disable Rails/SaveBang

    shared_examples 'weight is unchanged' do
      it 'does not change work item weight value' do
        expect { subject }
          .to not_change { work_item.weight }
      end
    end

    context 'when weight feature is licensed' do
      before do
        stub_licensed_features(issue_weights: true)
      end

      context 'when user can only update work item' do
        let(:params) { { weight: 2 } }

        before do
          project.add_guest(user)
        end

        it_behaves_like 'weight is unchanged'
      end

      context 'when user can admin work item' do
        before do
          project.add_reporter(user)
        end

        context 'when weight param is present' do
          let(:params) { { weight: 2 } }

          it 'correctly sets work item weight value' do
            subject

            expect(work_item.weight).to eq(2)
          end
        end

        context 'when weight param is not present' do
          let(:params) { {} }

          it_behaves_like 'weight is unchanged'
        end
      end
    end
  end
end
