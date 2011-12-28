# Subclass of Redcarpet's HTML renderer that includes SmartyPants
# quote-smartening.

class SmartyPantsHTML < Redcarpet::Render::HTML
  include Redcarpet::Render::SmartyPants
end
