# encoding: utf-8

require 'test/helper'

class Nanoc3::DataSources::FilesystemTest < MiniTest::Unit::TestCase

  include Nanoc3::TestHelpers

  # Test preparation

  def test_setup
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Remove files to make sure they are recreated
    FileUtils.rm_rf('content')
    FileUtils.rm_rf('layouts/default')
    FileUtils.rm_rf('lib/default.rb')

    # Mock VCS
    vcs = mock
    vcs.expects(:add).times(3) # One time for each directory
    data_source.vcs = vcs

    # Recreate files
    data_source.setup

    # Ensure essential files have been recreated
    assert(File.directory?('content/'))
    assert(File.directory?('layouts/'))
    assert(File.directory?('lib/'))

    # Ensure no non-essential files have been recreated
    assert(!File.file?('content/content.html'))
    assert(!File.file?('content/content.yaml'))
    assert(!File.directory?('layouts/default/'))
    assert(!File.file?('lib/default.rb'))
  end

  # Test loading data

  def test_items
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create foo item
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.yaml', 'w') do |io|
      io.write("---\n")
      io.write("title: Foo\n")
    end
    File.open('content/foo/foo.html', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Create bar item
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar/bar.yaml', 'w') do |io|
      io.write("---\n")
      io.write("title: Bar\n")
    end
    File.open('content/bar/bar.html', 'w') do |io|
      io.write("Lorem ipsum dolor sit amet...")
    end

    # Load items
    items = data_source.items

    # Check items
    assert_equal(2, items.size)
    assert(items.any? { |a| a[:title] == 'Foo' })
    assert(items.any? { |a| a[:title] == 'Bar' })
  end

  def test_items_with_period_in_name_disallowing_periods_in_identifiers
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create foo.css
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/foo.css', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create bar.css.erb
    FileUtils.mkdir_p('content/bar')
    File.open('content/bar/bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Bar' }))
    end
    File.open('content/bar/bar.css.erb', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    items = data_source.items.sort_by { |i| i[:title] }
    
    # Check
    assert_equal 2, items.size
    assert_equal '/bar/', items[0].identifier
    assert_equal 'Bar',   items[0][:title]
    assert_equal '/foo/', items[1].identifier
    assert_equal 'Foo',   items[1][:title]
  end

  def test_items_with_period_in_name_allowing_periods_in_identifiers
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Create foo.css
    FileUtils.mkdir_p('content/foo')
    File.open('content/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo' }))
    end
    File.open('content/foo/foo.css', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create foo.bar.css
    FileUtils.mkdir_p('content/foo.bar')
    File.open('content/foo.bar/foo.bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'title' => 'Foo Bar' }))
    end
    File.open('content/foo.bar/foo.bar.css', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    items = data_source.items
    
    # Check
    assert_equal 2, items.size
    assert_equal '/foo/',     items[0].identifier
    assert_equal 'Foo',       items[0][:title]
    assert_equal '/foo.bar/', items[1].identifier
    assert_equal 'Foo Bar',   items[1][:title]
  end

  def test_layouts
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create layout
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write("---\n")
      io.write("filter: erb\n")
    end
    File.open('layouts/foo/foo.rhtml', 'w') do |io|
      io.write('Lorem ipsum dolor sit amet...')
    end

    # Load layouts
    layouts = data_source.layouts

    # Check layouts
    assert_equal(1,     layouts.size)
    assert_equal('erb', layouts[0][:filter])
  end

  def test_layouts_with_period_in_name_disallowing_periods_in_identifiers
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create foo.html
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'dog' => 'woof' }))
    end
    File.open('layouts/foo/foo.html', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create bar.html.erb
    FileUtils.mkdir_p('layouts/bar')
    File.open('layouts/bar/bar.yaml', 'w') do |io|
      io.write(YAML.dump({ 'cat' => 'meow' }))
    end
    File.open('layouts/bar/bar.html.erb', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    layouts = data_source.layouts.sort_by { |i| i.identifier }
    
    # Check
    assert_equal 2, layouts.size
    assert_equal '/bar/', layouts[0].identifier
    assert_equal 'meow',  layouts[0][:cat]
    assert_equal '/foo/', layouts[1].identifier
    assert_equal 'woof',  layouts[1][:dog]
  end

  def test_layouts_with_period_in_name_allowing_periods_in_identifiers
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Create foo.html
    FileUtils.mkdir_p('layouts/foo')
    File.open('layouts/foo/foo.yaml', 'w') do |io|
      io.write(YAML.dump({ 'dog' => 'woof' }))
    end
    File.open('layouts/foo/foo.html', 'w') do |io|
      io.write('body.foo {}')
    end
    
    # Create bar.html.erb
    FileUtils.mkdir_p('layouts/bar.xyz')
    File.open('layouts/bar.xyz/bar.xyz.yaml', 'w') do |io|
      io.write(YAML.dump({ 'cat' => 'meow' }))
    end
    File.open('layouts/bar.xyz/bar.xyz.html', 'w') do |io|
      io.write('body.foobar {}')
    end
    
    # Load
    layouts = data_source.layouts.sort_by { |i| i.identifier }
    
    # Check
    assert_equal 2, layouts.size
    assert_equal '/bar.xyz/', layouts[0].identifier
    assert_equal 'meow',      layouts[0][:cat]
    assert_equal '/foo/',     layouts[1].identifier
    assert_equal 'woof',      layouts[1][:dog]
  end

  # Test creating data

  def test_create_item_at_root
    # Create item
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/')

    # Check file existance
    assert File.directory?('content')
    assert File.file?('content/content.html')
    assert File.file?('content/content.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/content.html')
    assert_match 'foo: bar',     File.read('content/content.yaml')
  end

  def test_create_item_not_at_root
    # Create item
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)
    data_source.create_item('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('content/moo')
    assert File.file?('content/moo/moo.html')
    assert File.file?('content/moo/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('content/moo/moo.html')
    assert_match 'foo: bar',     File.read('content/moo/moo.yaml')
  end

  def test_create_layout
    # Create layout
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)
    data_source.create_layout('content here', { :foo => 'bar' }, '/moo/')

    # Check file existance
    assert File.directory?('layouts/moo')
    assert File.file?('layouts/moo/moo.html')
    assert File.file?('layouts/moo/moo.yaml')

    # Check file content
    assert_equal 'content here', File.read('layouts/moo/moo.html')
    assert_match 'foo: bar',     File.read('layouts/moo/moo.yaml')
  end

  # Test private methods

  def test_meta_filenames_good_allowing_periods_in_identifiers
    # Create data sources
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, { :allow_periods_in_identifiers => true })

    # Create files
    FileUtils.mkdir_p('foo')
    File.open('foo/foo.yaml', 'w') { |io| io.write('foo') }
    FileUtils.mkdir_p('foo.bar')
    File.open('foo.bar/foo.bar.yaml', 'w') { |io| io.write('foo') }

    # Check
    assert_equal %w( ./foo/foo.yaml ./foo.bar/foo.bar.yaml ), data_source.send(:meta_filenames, '.')
  end

  def test_meta_filenames_good_disallowing_periods_in_identifiers
    # Create data sources
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create files
    FileUtils.mkdir_p('foo')
    File.open('foo/foo.yaml', 'w') { |io| io.write('foo') }
    FileUtils.mkdir_p('bar')
    File.open('bar/bar.yaml', 'w') { |io| io.write('bar') }

    # Check
    assert_equal %w( ./foo/foo.yaml ./bar/bar.yaml ).sort, data_source.send(:meta_filenames, '.').sort
  end

  def test_meta_filenames_bad
    # Create data sources
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create files
    FileUtils.mkdir_p('foo')
    File.open('foo/dsafsdf.yaml', 'w') { |io| io.write('dagasfwegfwa') }

    # Check
    assert_raises(RuntimeError) do
      data_source.send(:meta_filenames, '.')
    end
  end

  def test_content_filename_for_dir_with_one_content_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_two_content_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.xhtml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_raises(RuntimeError) do
      assert_equal(
        'foo/bar/baz/baz.html',
        data_source.instance_eval do
          content_filename_for_dir('foo/bar/baz')
        end
      )
    end
  end

  def test_content_filename_for_dir_with_one_content_and_one_meta_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_and_many_meta_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/foo.yaml', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/zzz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_file_and_rejected_files
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html~', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html.orig', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html.rej', 'w') { |io| io.write('test') }
    File.open('foo/bar/baz/baz.html.bak', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_index_content_file
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/bar/baz')
    File.open('foo/bar/baz/index.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'foo/bar/baz/index.html',
      data_source.instance_eval do
        content_filename_for_dir('foo/bar/baz')
      end
    )
  end

  # Miscellaneous

  def test_meta_filenames_error
    # TODO implement
  end

  def test_content_filename_for_dir_error
    # TODO implement
  end

  def test_content_filename_for_dir_index_error
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Build directory
    FileUtils.mkdir_p('foo/index')
    File.open('foo/index/index.html', 'w') { |io| io.write('test') }

    # Check
    assert_equal(
      'foo/index/index.html',
      data_source.instance_eval { content_filename_for_dir('foo/index') }
    )
  end

  def test_compile_huge_site
    # Create data source
    data_source = Nanoc3::DataSources::Filesystem.new(nil, nil, nil, nil)

    # Create a lot of items
    count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
    count.times do |i|
      FileUtils.mkdir_p("content/#{i}")
      File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is item #{i}." }
      File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Item #{i}"   }
    end

    # Read all items
    data_source.items
  end

end
