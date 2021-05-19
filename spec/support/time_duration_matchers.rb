RSpec::Matchers.define :take_less_than do |duration|
  match do |lambda|
    start = Time.now
    lambda.call
    finish = Time.now 
    finish - start < duration
  end
end

RSpec::Matchers.define :take_more_than do |duration|
  match do |lambda|
    start = Time.now
    lambda.call
    finish = Time.now 
    finish - start > duration
  end
end

