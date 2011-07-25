# Use the Compass SASS library with the Rails 3.1 asset pipeline.

Sass::Engine::DEFAULT_OPTIONS[:load_paths] << Rails.root.join('app', 'assets', 'stylesheets')
Sass::Engine::DEFAULT_OPTIONS[:load_paths] << File.join(Gem.loaded_specs['compass'].full_gem_path, 'frameworks', 'compass', 'stylesheets')
