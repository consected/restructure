class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

   has_many :user_roles, class_name: 'Admin::UserRole'
   belongs_to :app_type, class_name: 'Admin::AppType'
   before_validation :set_defaults


   def app_type_valid?
     true
   end


   private

     def set_defaults
       self.app_type ||= Admin::AppType.first
     end

end
