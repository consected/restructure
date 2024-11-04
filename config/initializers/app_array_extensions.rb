module ArrayExtensions
  def mean
    not_nil = compact
    not_nil.sum.to_f / not_nil.count
  end

  def count_not_null
    count(&:itself)
  end
end

class Array
  include ArrayExtensions
end
