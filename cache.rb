class Cache
  def initialize
    @cache = {}
  end
  
  def cached(key)
    @cache[key] or @cache[key] = yield
  end
end
