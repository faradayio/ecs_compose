def stub(object, methods)
  methods.each do |method, value|
    allow(object).to receive(method).and_return value
  end
end

