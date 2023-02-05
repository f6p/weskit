module Weskit::WML
  class Preprocessor
    attr_reader :data

    def initialize data
      @data = data.to_s
    end

    def remove_directives
      directives.reduce(@data) {|r, d| r.gsub d, ''}
    end

    def directives
      [
        /#define.+?#enddef/m,
        /#undef.+/,

        /#ifn?def.+?#endif/m,
        /#ifn?have.+?#endif/m,
        /#ifn?ver.+?#endif/m,
        /#endif/,

        /\{.*?\}/
      ]
    end
  end
end
