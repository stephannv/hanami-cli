# frozen_string_literal: true

require "dry/files"

module Hanami
  module CLI
    # @since 2.0.0
    # @api private
    class Files < Dry::Files
      # @since 2.0.0
      # @api private
      def initialize(out: $stdout, input: $stdin, **args)
        super(**args)
        @out = out
        @input = input
      end

      # @api private
      def create(path, *content)
        if exist?(path)
          handle_file_conflict(path, *content)
        else
          write(path, *content)
        end
      end

      # @since 2.0.0
      # @api private
      def write(path, *content)
        already_exists = exist?(path)

        super

        delete_keepfiles(path) unless already_exists

        if already_exists
          updated(path)
        else
          created(path)
        end
      end

      # @since 2.0.0
      # @api private
      def mkdir(path)
        return if exist?(path)

        super
        created(_path(path))
      end

      # @since 2.0.0
      # @api private
      def chdir(path, &blk)
        within_folder(path)
        super
      end

      private

      POSITIVE_ANSWERS = ["yes", "y"].freeze
      private_constant :POSITIVE_ANSWERS

      attr_reader :out, :input

      # Removes .keep files in any directories leading up to the given path.
      #
      # Does not attempt to remove `.keep` files in the following scenarios:
      #   - When the given path is a `.keep` file itself.
      #   - When the given path is absolute, since ascending up this path may lead to removal of
      #     files outside the Hanami project directory.
      def delete_keepfiles(path)
        path = Pathname(path)

        return if path.absolute?
        return if path.relative_path_from(path.dirname).to_s == ".keep"

        path.dirname.ascend do |part|
          keepfile = (part + ".keep").to_path
          delete(keepfile) if exist?(keepfile)
        end
      end

      def updated(path)
        out.puts "Updated #{path}"
      end

      def created(path)
        out.puts "Created #{path}"
      end

      def within_folder(path)
        out.puts "-> Within #{_path(path)}"
      end

      def _path(path)
        path + ::File::SEPARATOR
      end

      def handle_file_conflict(path, *content)
        out.puts "The file `#{path}` already exists. Would you like to overwrite it? [y/N]"
        response = input.gets&.chomp&.downcase

        case response
        when *POSITIVE_ANSWERS
          write(path, *content)
        else
          raise FileAlreadyExistsError.new(path)
        end
      end
    end
  end
end
