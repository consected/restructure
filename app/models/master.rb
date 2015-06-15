class Master < ActiveRecord::Base

  # inverse_of required to ensure the current_user propagates between associated models correctly
  has_many :player_infos, inverse_of: :master
  has_many :manual_investigations  
  has_many :pro_infos
  
  has_many :player_contacts
  has_many :addresses
  
  # TODO - make this real!
  has_one :address, -> { where rank: 1 }
  
  
  accepts_nested_attributes_for :player_infos, :pro_infos, :manual_investigations, :player_contacts, :address, :addresses
  
  # Build a Master search using the Master and nested attributes passed in
  # Any attributes that are nil will be rejected and will not appear in the query
  # Tables will only be joined if the nested attributes for the association have one or more
  # attributes that are not nil
  def self.search_on_params params
    
    joins = []
    wheres = {}
    selects = []
    
    params.each do |k,v|
      logger.info "k: #{k}"
      
      
      if v.is_a? Hash
      
        if v.first.first == "0"
          v = v.first.last
        end
        
        # Handle nested attributes
        # Get the key name for the table by removing the _attributes extension from the key
        k1 = k.to_s.gsub('_attributes','')
        # Generate a pluralized table name for associations that are has_one
        k1s = k1.pluralize
        # Keep only non-nil attributes
        vn = v.select {|_,v1| !v1.nil?}
        # If we have a set of attributes that is not empty 
        # add the equality conditions to the list of wheres
        if vn.length > 0
          wheres[k1s] = vn
          joins << k1.to_sym        
        end
        # Always add the table to the list of joins and select (so we can get the data)
        
      elsif !v.nil?
        # Handle Master level attributes
        wheres[k] = v
      end
      
    end
    
    Master.select(selects).joins(joins).where(wheres)
    
  end
  
#  def as_json options=nil
#    
#    {
#      id: id, 
#      player_infos: player_infos.order(rank: :desc),
#      #pro_infos: pros,
#      player_contacts: player_contacts.order(rank: :desc), 
#      manual_investigations: manual_investigations(rank: :desc), 
#      addresses: addresses.order(rank: :desc)      
#    }
#    
#  end

  def current_user= cu
    logger.info "Setting current user: #{cu} in #{self}"
    @user_id = cu
  end
  
  def current_user
    @user_id
  end
  
private

  
end
