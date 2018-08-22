Admin::AppType.create! name: 'app 1' unless Admin::AppType.where(name: 'app 1').first
Admin::AppType.create! name: 'app 2' unless Admin::AppType.where(name: 'app 2').first
