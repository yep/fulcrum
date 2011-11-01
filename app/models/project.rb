class Project < ActiveRecord::Base

  JSON_ATTRIBUTES = [
    "id", "iteration_length", "iteration_start_day", "start_date",
    "default_velocity"
  ]
  JSON_METHODS = ["last_changeset_id", "point_values"]

  # These are the valid point scalse for a project.  These represent
  # the set of valid points estimate values for a story in this project.
  POINT_SCALES = {
    'fibonacci'     => [0,1,2,3,5,8],
    'powers_of_two' => [0,1,2,4,8],
    'linear'        => [0,1,2,3,4,5],
  }
  validates_inclusion_of :point_scale, :in => POINT_SCALES.keys,
    :message => "%{value} is not a valid estimation scheme"

  ITERATION_LENGTH_RANGE = (1..4)
  validates_numericality_of :iteration_length,
    :greater_than_or_equal_to => ITERATION_LENGTH_RANGE.min,
    :less_than_or_equal_to => ITERATION_LENGTH_RANGE.max, :only_integer => true,
    :message => "must be between 1 and 4 weeks"

  validates_numericality_of :iteration_start_day,
    :greater_than_or_equal_to => 0, :less_than_or_equal_to => 6,
    :only_integer => true, :message => "must be an integer between 0 and 6"

  validates :name, :presence => true

  validates_numericality_of :default_velocity, :greater_than => 0,
                            :only_integer => true

  has_and_belongs_to_many :users, :uniq => true
  accepts_nested_attributes_for :users, :reject_if => :all_blank

  has_many :stories, :dependent => :destroy do

    # Populates the stories collection from a CSV string.
    def from_csv(csv_string)

      # Eager load this so that we don't have to make multiple db calls when
      # searching for users by full name from the CSV.
      users = proxy_owner.users

      # This will store an array of hashes of the story attributes from the
      # CSV
      stories = []

      csv = CSV.parse(csv_string, :headers => true)
      csv.each do |row|
        row = row.to_hash
        stories << {
          :state => row["Current State"],
          :title => row["Story"],
          :story_type => row["Story Type"],
          :requested_by => users.detect {|u| u.name == row["Requested By"]},
          :owned_by => users.detect {|u| u.name == row["Owned By"]},
          :accepted_at => row["Accepted at"],
          :estimate => row["Estimate"],
          :labels => row["Labels"]
        }
      end
      create(stories)
    end

  end
  has_many :changesets, :dependent => :destroy

  attr_accessor_with_default :suppress_notifications, false

  def to_s
    name
  end

  # Returns an array of the valid points values for this project
  def point_values
    POINT_SCALES[point_scale]
  end

  def last_changeset_id
    changesets.last && changesets.last.id
  end

  def as_json(options = {})
    super(:only => JSON_ATTRIBUTES, :methods => JSON_METHODS)
  end

  def csv_filename
    "#{name}-#{Time.now.strftime('%Y%m%d_%I%M')}.csv"
  end
end
