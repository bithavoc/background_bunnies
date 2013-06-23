module BackgroundBunnies

  def self.warn(a)
    $stderr.puts "[warn] BackgroundBunnies -> #{a}"
  end

  def self.info(a)
    $stdout.puts "[info] BackgroundBunnies -> #{a}"
  end

  def self.error(a)
    $stderr.puts "[error] BackgroundBunnies -> #{a}"
  end

end
