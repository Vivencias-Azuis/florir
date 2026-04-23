require "pathname"

RSpec.describe "Controller thinness" do
  let(:root) { Pathname.new(File.expand_path("../..", __dir__)) }

  it "avoids likely ActiveRecord query chains inside controllers" do
    controller_files = Dir[root.join("app/controllers/**/*_controller.rb")]
    next skip("no controllers found") if controller_files.empty?

    offenders = controller_files.select do |file|
      content = File.read(file)
      content.match?(/\.(where|joins|left_joins|pluck|find_by|find_by!|group|order|includes)\(/)
    end

    expect(offenders).to be_empty, <<~MSG
      Controllers should delegate query-heavy work.
      Offenders:
      #{offenders.join("\n")}
    MSG
  end
end
