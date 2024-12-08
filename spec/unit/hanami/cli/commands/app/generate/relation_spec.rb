# frozen_string_literal: true

RSpec.describe Hanami::CLI::Commands::App::Generate::Relation, :app do
  subject { described_class.new(fs: fs, inflector: inflector, out: out) }

  let(:fs) { Hanami::CLI::Files.new(memory: true, out: out, input: input) }
  let(:out) { StringIO.new }
  let(:input) { StringIO.new }
  let(:inflector) { Dry::Inflector.new }
  let(:app) { Hanami.app.namespace }

  def output = out.string

  context "generating for app" do
    it "generates a relation" do
      subject.call(name: "books")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Test
          module Relations
            class Books < Test::DB::Relation
              schema :books, infer: true
            end
          end
        end
      RUBY

      expect(fs.read("app/relations/books.rb")).to eq relation_file
      expect(output).to include("Created app/relations/books.rb")
    end

    it "generates a relation in a namespace with default separator" do
      subject.call(name: "books.drafts")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Test
          module Relations
            module Books
              class Drafts < Test::DB::Relation
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("app/relations/books/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created app/relations/books/drafts.rb")
    end

    it "generates an relation in a namespace with slash separators" do
      subject.call(name: "books/published_books")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Test
          module Relations
            module Books
              class PublishedBooks < Test::DB::Relation
                schema :published_books, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("app/relations/books/published_books.rb")).to eq(relation_file)
      expect(output).to include("Created app/relations/books/published_books.rb")
    end

    it "deletes the redundant .keep file" do
      fs.write "app/relations/.keep", ""

      expect { subject.call(name: "books") }
        .to change { fs.exist?("app/relations/.keep") }
        .to false
    end

    it "generates a relation for gateway" do
      subject.call(name: "books", gateway: "extra")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Test
          module Relations
            class Books < Test::DB::Relation
              gateway :extra
              schema :books, infer: true
            end
          end
        end
      RUBY

      expect(fs.read("app/relations/books.rb")).to eq relation_file
      expect(output).to include("Created app/relations/books.rb")
    end

    context "with existing file" do
      before do
        fs.write "app/relations/books.rb", "existing content"
      end

      context "with positive answer for overwrite question" do
        let(:input) { StringIO.new("y\n")}

        it "overwrites file" do
          subject.call(name: "books")

          expect(output).to include("Updated app/relations/books.rb")
        end
      end

      context "with negative answer for overwrite question" do
        it "raises error" do
          expect { subject.call(name: "books") }
            .to raise_error(Hanami::CLI::FileAlreadyExistsError)
        end
      end
    end
  end

  context "generating for a slice" do
    it "generates a relation" do
      subject.call(name: "books", slice: "main")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Main
          module Relations
            class Books < Main::DB::Relation
              schema :books, infer: true
            end
          end
        end
      RUBY

      expect(fs.read("slices/main/relations/books.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/books.rb")
    end

    it "generates a relation in a nested namespace" do
      subject.call(name: "book.drafts", slice: "main")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Main
          module Relations
            module Book
              class Drafts < Main::DB::Relation
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("slices/main/relations/book/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end

    it "generates a relation for gateway" do
      subject.call(name: "book.drafts", slice: "main", gateway: "extra")

      relation_file = <<~RUBY
        # frozen_string_literal: true

        module Main
          module Relations
            module Book
              class Drafts < Main::DB::Relation
                gateway :extra
                schema :drafts, infer: true
              end
            end
          end
        end
      RUBY

      expect(fs.read("slices/main/relations/book/drafts.rb")).to eq(relation_file)
      expect(output).to include("Created slices/main/relations/book/drafts.rb")
    end

    it "deletes the redundant .keep file" do
      fs.write "slices/main/.keep", ""

      expect { subject.call(name: "books", slice: "main") }
        .to change { fs.exist?("slices/main/.keep") }
        .to false
    end

    context "with existing file" do
      before do
        fs.write "slices/main/relations/books.rb", "existing content"
      end

      context "with positive answer for overwrite question" do
        let(:input) { StringIO.new("y\n")}

        it "overwrites file" do
          subject.call(name: "books", slice: "main")

          expect(output).to include("Updated slices/main/relations/books.rb")
        end
      end

      context "with negative answer for overwrite question" do
        it "raises error" do
          expect { subject.call(name: "books", slice: "main") }
            .to raise_error(Hanami::CLI::FileAlreadyExistsError)
        end
      end
    end
  end
end
