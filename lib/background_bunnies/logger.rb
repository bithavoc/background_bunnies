module BackgroundBunnies

  def self.log(a)
    p "[log] BackgroundBunnies -> #{a}"
  end

  def self.info(a)
    p "[info] BackgroundBunnies -> #{a}"
  end

  def self.error(a)
    $stderr.puts "[error] BackgroundBunnies -> #{a}"
  end

end
