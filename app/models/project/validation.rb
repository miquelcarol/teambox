class Project

  validates_length_of :name, :minimum => 5, :on => :create  # New projects
  validates_length_of :name, :minimum => 5, :on => :update, :if => :name_changed?  # Changing the name
  validates_length_of :name, :minimum => 3, :on => :update  # Legacy validation for existing projects
  validates_uniqueness_of :permalink, :case_sensitive => false
  validates_length_of :permalink, :minimum => 5
  validates_format_of :permalink, :with => /^[a-z0-9_\-]{5,}$/, :if => :permalink_length_valid?

  # needs an owner
  validates_presence_of :user         # A project _needs_ an owner
  
  def permalink_length_valid?
    self.permalink.length >= 5
  end

end