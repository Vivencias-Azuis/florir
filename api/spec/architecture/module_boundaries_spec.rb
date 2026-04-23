require "pathname"

RSpec.describe "Module boundaries" do
  let(:root) { Pathname.new(File.expand_path("../..", __dir__)) }

  it "does not allow external HTTP clients inside app/models" do
    model_files = Dir[root.join("app/models/**/*.rb")]
    next skip("no app/models directory found") if model_files.empty?

    offenders = model_files.select do |file|
      content = File.read(file)
      content.match?(/Net::HTTP|Faraday|HTTParty|RestClient|HTTP\.|Excon|Typhoeus/)
    end

    expect(offenders).to be_empty, <<~MSG
      Models should not perform external IO directly.
      Offenders:
      #{offenders.join("\n")}
    MSG
  end
end
