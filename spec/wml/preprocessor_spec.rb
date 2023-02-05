require 'wml_spec_helper'

describe Weskit::WML::Preprocessor do
  specify 'removes directives' do
    document = <<-DOC
      #define TEST
        a=b
      #enddef

      #undef TEST
      {TEST}

      #ifdef TEST
        {TEST}
      #else
        #ifdef BAR
          {BAR}
        #endif
      #endif
    DOC

    preprocessed = Weskit::WML::Preprocessor.new(document).remove_directives
    preprocessed.strip.should be_empty
  end
end
