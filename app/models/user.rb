class User < ActiveRecord::Base

  hobo_user_model # Don't put anything above this

  fields do

    # NOTE: If you add fields here, you may need to include them in both the attr_accessible list, and
    # the list of fields passed to 'only_changed?' in the update_permitted? method for them to appear 
    # on the user#edit form.

    name          :string, :required, :unique
    email_address :email_address, :login => true
    administrator :boolean, :default => false
    timestamps
  end
  attr_accessible :name, :email_address, :password, :password_confirmation, :current_password, :task_assignments, :tasks
  
  validates_presence_of :name
  
  has_many :task_assignments, :dependent => :destroy, :inverse_of => :user
  has_many :tasks, :through => :task_assignments

  # This gives admin rights and an :active state to the first sign-up.
  # Just remove it if you don't want that
  before_create do |user|
    if !Rails.env.test? && user.class.count == 0
      user.administrator = true
      user.state = "active"
    end
  end


  # --- Signup lifecycle --- #

  lifecycle do

    state :inactive, :default => true
    state :active

    create :signup, :available_to => "Guest",
      :params => [:name, :email_address, :password, :password_confirmation],
      :become => :inactive, :new_key => true  do
      UserMailer.activation(self, lifecycle.key).deliver_now
    end

    transition :activate, { :inactive => :active }, :available_to => :key_holder

    transition :request_password_reset, { :inactive => :inactive }, :new_key => true do
      UserMailer.activation(self, lifecycle.key).deliver_now
    end

    transition :request_password_reset, { :active => :active }, :new_key => true do
      UserMailer.forgot_password(self, lifecycle.key).deliver_now
    end

    transition :reset_password, { :active => :active }, :available_to => :key_holder,
               :params => [ :password, :password_confirmation ]

  end

  def signed_up?
    state=="active"
  end

  # --- Permissions --- #

  def create_permitted?
    # Only the initial admin user can be created
    self.class.count == 0
  end

  def update_permitted?
    acting_user.administrator? ||
      (acting_user == self && only_changed?(:email_address, :crypted_password,
                                            :current_password, :password, :password_confirmation))
    # Note: crypted_password has attr_protected so although it is permitted to change, it cannot be changed
    # directly from a form submission.
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end
end
