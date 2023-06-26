require 'rails_helper'

RSpec.describe SaveTriggers::PullExternalData, type: :model do
  include ModelSupport
  include ActivityLogSupport

  def api_uri
    'https://rspec.mktorest.com'
  end

  def client_auth_url
    '/identity/oauth/token?client_id=abcdef-1234-5678-gggggggg&client_secret=rspectestsecret&grant_type=client_credentials'
  end

  before :example do
    # SetupHelper.get_webmock_responses
    # WebMock.allow_net_connect!

    content = <<~END_CONTENT
      <?xml version="1.0" ?>
      <!DOCTYPE PubmedArticleSet PUBLIC "-//NLM//DTD PubMedArticle, 1st January 2019//EN" "https://dtd.nlm.nih.gov/ncbi/pubmed/out/pubmed_190101.dtd">
      <PubmedArticleSet><PubmedArticle><MedlineCitation Status="MEDLINE" Owner="NLM"><PMID Version="1">14760269</PMID><DateCompleted><Year>2004</Year><Month>03</Month><Day>16</Day></DateCompleted><DateRevised><Year>2016</Year><Month>11</Month><Day>22</Day></DateRevised><Article PubModel="Print"><Journal><ISSN IssnType="Print">0022-3476</ISSN><JournalIssue CitedMedium="Print"><Volume>144</Volume><Issue>2</Issue><PubDate><Year>2004</Year><Month>Feb</Month></PubDate></JournalIssue><Title>The Journal of pediatrics</Title><ISOAbbreviation>J Pediatr</ISOAbbreviation></Journal><ArticleTitle>Maternal age and other predictors of newborn blood pressure.</ArticleTitle><Pagination><MedlinePgn>240-5</MedlinePgn></Pagination><Abstract><AbstractText Label="OBJECTIVE" NlmCategory="OBJECTIVE">To investigate perinatal predictors of newborn blood pressure.</AbstractText><AbstractText Label="STUDY DESIGN" NlmCategory="METHODS">Among 1059 mothers and their newborn infants participating in Project Viva, a US cohort study of pregnant women and their offspring, we obtained five systolic blood pressure readings on a single occasion in the first few days of life. Using multivariate linear regression models, we examined the extent to which maternal age and other pre- and perinatal factors predicted newborn blood pressure level.</AbstractText><AbstractText Label="RESULTS" NlmCategory="RESULTS">Mean (SD) maternal age was 32.0 (5.2) years, and mean (SD) newborn systolic blood pressure was 72.6 (9.0) mm Hg. A multivariate model showed that for each 5-year increase in maternal age, newborn systolic blood pressure was 0.8 mm Hg higher (95% CI, 0.2, 1.4). In addition to maternal age, independent predictors of newborn blood pressure included maternal third trimester blood pressure (0.9 mm Hg [95% CI, 0.2, 1.6] for each increment in maternal blood pressure); infant age at which we measured blood pressure (2.4 mm Hg [95% CI 1.7, 3.0] for each additional day of life); and birth weight (2.9 mm Hg [95% CI, 1.6, 4.2] per kg).</AbstractText><AbstractText Label="CONCLUSIONS" NlmCategory="CONCLUSIONS">Higher maternal age, maternal blood pressure, and birth weight were associated with higher newborn systolic blood pressure. Whereas blood pressure later in childhood predicts adult hypertension and its consequences, newborn blood pressure may represent different phenomena, such as pre- and perinatal influences on cardiac structure and function.</AbstractText></Abstract><AuthorList CompleteYN="Y"><Author ValidYN="Y"><LastName>Gillman</LastName><ForeName>Matthew W</ForeName><Initials>MW</Initials><AffiliationInfo><Affiliation>Department of Ambulatory Care and Prevention, Harvard Medical School/Harvard Pilgrim Health Care, Department of Obstetrics and Gynecology, Brigham and Women's Hospital, Harvard Medical School, Boston, Massachusetts, USA. matthew_gillman@hms.harvard.edu</Affiliation></AffiliationInfo></Author><Author ValidYN="Y"><LastName>Rich-Edwards</LastName><ForeName>Janet W</ForeName><Initials>JW</Initials></Author><Author ValidYN="Y"><LastName>Rifas-Shiman</LastName><ForeName>Sheryl L</ForeName><Initials>SL</Initials></Author><Author ValidYN="Y"><LastName>Lieberman</LastName><ForeName>Ellice S</ForeName><Initials>ES</Initials></Author><Author ValidYN="Y"><LastName>Kleinman</LastName><ForeName>Ken P</ForeName><Initials>KP</Initials></Author><Author ValidYN="Y"><LastName>Lipshultz</LastName><ForeName>Steven E</ForeName><Initials>SE</Initials></Author></AuthorList><Language>eng</Language><GrantList CompleteYN="Y"><Grant><GrantID>R01 HD034568-02</GrantID><Acronym>HD</Acronym><Agency>NICHD NIH HHS</Agency><Country>United States</Country></Grant><Grant><GrantID>K24 HL068041-02</GrantID><Acronym>HL</Acronym><Agency>NHLBI NIH HHS</Agency><Country>United States</Country></Grant><Grant><GrantID>HL68041</GrantID><Acronym>HL</Acronym><Agency>NHLBI NIH HHS</Agency><Country>United States</Country></Grant><Grant><GrantID>R01 HL064925-02</GrantID><Acronym>HL</Acronym><Agency>NHLBI NIH HHS</Agency><Country>United States</Country></Grant><Grant><GrantID>HD 34568</GrantID><Acronym>HD</Acronym><Agency>NICHD NIH HHS</Agency><Country>United States</Country></Grant><Grant><GrantID>HL64925</GrantID><Acronym>HL</Acronym><Agency>NHLBI NIH HHS</Agency><Country>United States</Country></Grant></GrantList><PublicationTypeList><PublicationType UI="D016428">Journal Article</PublicationType><PublicationType UI="D013485">Research Support, Non-U.S. Gov't</PublicationType><PublicationType UI="D013487">Research Support, U.S. Gov't, P.H.S.</PublicationType></PublicationTypeList></Article><MedlineJournalInfo><Country>United States</Country><MedlineTA>J Pediatr</MedlineTA><NlmUniqueID>0375410</NlmUniqueID><ISSNLinking>0022-3476</ISSNLinking></MedlineJournalInfo><CitationSubset>IM</CitationSubset><CommentsCorrectionsList><CommentsCorrections RefType="CommentIn"><RefSource>J Pediatr. 2005 Jan;146(1):148-9; author reply 149</RefSource><PMID Version="1">15644849</PMID></CommentsCorrections></CommentsCorrectionsList><MeshHeadingList><MeshHeading><DescriptorName UI="D000293" MajorTopicYN="N">Adolescent</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D000328" MajorTopicYN="N">Adult</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D000367" MajorTopicYN="N">Age Factors</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D001724" MajorTopicYN="N">Birth Weight</DescriptorName><QualifierName UI="Q000502" MajorTopicYN="N">physiology</QualifierName></MeshHeading><MeshHeading><DescriptorName UI="D001794" MajorTopicYN="N">Blood Pressure</DescriptorName><QualifierName UI="Q000502" MajorTopicYN="Y">physiology</QualifierName></MeshHeading><MeshHeading><DescriptorName UI="D015331" MajorTopicYN="N">Cohort Studies</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D005260" MajorTopicYN="N">Female</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D006339" MajorTopicYN="N">Heart Rate</DescriptorName><QualifierName UI="Q000502" MajorTopicYN="N">physiology</QualifierName></MeshHeading><MeshHeading><DescriptorName UI="D006801" MajorTopicYN="N">Humans</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D007231" MajorTopicYN="N">Infant, Newborn</DescriptorName><QualifierName UI="Q000502" MajorTopicYN="Y">physiology</QualifierName></MeshHeading><MeshHeading><DescriptorName UI="D016014" MajorTopicYN="N">Linear Models</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D008423" MajorTopicYN="Y">Maternal Age</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D015999" MajorTopicYN="N">Multivariate Analysis</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D011237" MajorTopicYN="N">Predictive Value of Tests</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D011247" MajorTopicYN="N">Pregnancy</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D011263" MajorTopicYN="N">Pregnancy Trimester, Third</DescriptorName></MeshHeading><MeshHeading><DescriptorName UI="D013599" MajorTopicYN="N">Systole</DescriptorName><QualifierName UI="Q000502" MajorTopicYN="N">physiology</QualifierName></MeshHeading></MeshHeadingList></MedlineCitation><PubmedData><History><PubMedPubDate PubStatus="pubmed"><Year>2004</Year><Month>2</Month><Day>5</Day><Hour>5</Hour><Minute>0</Minute></PubMedPubDate><PubMedPubDate PubStatus="medline"><Year>2004</Year><Month>3</Month><Day>18</Day><Hour>5</Hour><Minute>0</Minute></PubMedPubDate><PubMedPubDate PubStatus="entrez"><Year>2004</Year><Month>2</Month><Day>5</Day><Hour>5</Hour><Minute>0</Minute></PubMedPubDate></History><PublicationStatus>ppublish</PublicationStatus><ArticleIdList><ArticleId IdType="pubmed">14760269</ArticleId><ArticleId IdType="doi">10.1016/j.jpeds.2003.10.064</ArticleId><ArticleId IdType="pii">S0022-3476(03)00810-2</ArticleId></ArticleIdList></PubmedData></PubmedArticle></PubmedArticleSet>
    END_CONTENT

    stub_request(:get, 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=14760269&retmode=xml')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => /.*/,
          'Host' => 'eutils.ncbi.nlm.nih.gov',
          'User-Agent' => /.*/
        }
      )
      .to_return(status: 200, body: content, headers: {})

    content = <<~END_CONTENT
      {"header":{"type":"esummary", "version":"0.3"},
      "result":
        {"uids":["14760269"],
        "14760269":
          {"uid":"14760269",
          "pubdate":"2004 Feb",
          "epubdate":"",
          "source":"J Pediatr",
          "authors":
            [{"name":"Gillman MW", "authtype":"Author", "clusterid":""},
            {"name":"Rich-Edwards JW", "authtype":"Author", "clusterid":""},
            {"name":"Rifas-Shiman SL", "authtype":"Author", "clusterid":""},
            {"name":"Lieberman ES", "authtype":"Author", "clusterid":""},
            {"name":"Kleinman KP", "authtype":"Author", "clusterid":""},
            {"name":"Lipshultz SE", "authtype":"Author", "clusterid":""}],
          "lastauthor":"Lipshultz SE",
          "title":"Maternal age and other predictors of newborn blood pressure.",
          "sorttitle":
            "maternal age and other predictors of newborn blood pressure",
          "volume":"144",
          "issue":"2",
          "pages":"240-5",
          "lang":["eng"],
          "nlmuniqueid":"0375410",
          "issn":"0022-3476",
          "essn":"1097-6833",
          "pubtype":["Journal Article"],
          "recordstatus":"PubMed - indexed for MEDLINE",
          "pubstatus":"4",
          "articleids":
            [{"idtype":"pubmed", "idtypen":1, "value":"14760269"},
            {"idtype":"doi", "idtypen":3, "value":"10.1016/j.jpeds.2003.10.064"},
            {"idtype":"pii", "idtypen":4, "value":"S0022-3476(03)00810-2"},
            {"idtype":"rid", "idtypen":8, "value":"14760269"},
            {"idtype":"eid", "idtypen":8, "value":"14760269"}],
          "history":
            [{"pubstatus":"pubmed", "date":"2004/02/05 05:00"},
            {"pubstatus":"medline", "date":"2004/03/18 05:00"},
            {"pubstatus":"entrez", "date":"2004/02/05 05:00"}],
          "references":
            [{"refsource":"J Pediatr. 2005 Jan;146(1):148-9; author reply 149",
              "reftype":"Comment in",
              "pmid":15644849,
              "note":""}],
          "attributes":["Has Abstract"],
          "pmcrefcount":123,
          "fulljournalname":"The Journal of pediatrics",
          "elocationid":"",
          "doctype":"citation",
          "srccontriblist":[],
          "booktitle":"",
          "medium":"",
          "edition":"",
          "publisherlocation":"",
          "publishername":"",
          "srcdate":"",
          "reportnumber":"",
          "availablefromurl":"",
          "locationlabel":"",
          "doccontriblist":[],
          "docdate":"",
          "bookname":"",
          "chapter":"",
          "sortpubdate":"2004/02/01 00:00",
          "sortfirstauthor":"Gillman MW",
          "vernaculartitle":""}}}
    END_CONTENT

    stub_request(:get, 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=14760269&retmode=json')
      .with(
        headers: {
          'Accept' => /.*/,
          'Accept-Encoding' => /.*/,
          'Host' => /.*/,
          'User-Agent' => /.*/
        }
      )
      .to_return(status: 200, body: content, headers: {})

    stub_request(:get, 'https://eutils.ncbi.nlm.nih.gov/404page')
      .with(
        headers: {
          'Accept' => /.*/,
          'Accept-Encoding' => /.*/,
          'Host' => /.*/,
          'User-Agent' => /.*/
        }
      )
      .to_return(status: 404, body: content, headers: {})

    stub_request(:get, 'https://eutils.ncbi.nlm.nih.gov/blank')
      .with(
        headers: {
          'Accept' => /.*/,
          'Accept-Encoding' => /.*/,
          'Host' => /.*/,
          'User-Agent' => /.*/
        }
      )
      .to_return(status: 200, body: '', headers: {})

    stub_request(:post, "#{api_uri}#{client_auth_url}")
      .with(
        headers: {
          'Accept' => /.*/,
          'Accept-Encoding' => /.*/,
          'Host' => /.*/,
          'User-Agent' => /.*/,
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      )
      .to_return(
        status: 200,
        body: '{"access_token":"123123123-ad12-1234-99ce-893645:ab","token_type":"bearer","expires_in":3559,"scope":"rspecemail@test.tst"}',
        headers: {}
      )

    stub_request(:get, "#{api_uri}/rest/v1/campaigns/1081.json?access_token=123123123-ad12-1234-99ce-893645:ab")
      .with(
        headers: {
          'Accept' => /.*/,
          'Accept-Encoding' => /.*/,
          'Host' => /.*/,
          'User-Agent' => /.*/
        }
      )
      .to_return(status: 200, body: '{"requestId":"6346#87d796ac7","result":[{"id":1081,"name":"Annual Revenue","description":"Run this Campaign at least once as a Batch Campaign, so it can score all the existing leads in your database. Then you can either schedule it to run every night, or you can add the following two triggers: \"Lead is Created\" AND \"Data Value Changes\" in the \"Annual Revenue\" Field.","type":"batch","programName":"OP-Scoring-Demographic","programId":1014,"workspaceName":"Default","createdAt":"2014-06-27T02:58:28Z","updatedAt":"2016-03-24T08:27:50Z","active":false}],"success":true}', headers: {})

    stub_request(:post, "#{api_uri}/rest/v1/leads/push.json?access_token=123123123-ad12-1234-99ce-893645:ab")
      .with(
        body: /\{"programName":"HCI Participant Import","lookupField":"email","source":"HCIQ Zeus","reason":"Changed status","input":\[\{"email":"phil-test12@consected.com","firstName":"Test FN","lastName":"Test LN","hCIStage":"Invitation Email","hCIStageUpdatedAt":".*","hCIQLink":".*"\}\]\}/,
        headers: {
          'Accept' => /.*/,
          'Accept-Encoding' => /.*/,
          'Host' => /.*/,
          'User-Agent' => /.*/,
          'Content-Type' => 'application/json'
        }
      )
      .to_return(
        status: 200,
        headers: {},
        body: '{"requestId": "71c5#187e7d99f13","result": [{"id": 30412, "status": "updated"}],"success": true}'
      )
  end

  before :example do
    SetupHelper.setup_al_player_contact_phones
    res = SetupHelper.setup_al_gen_tests 'Test Pull External', 'test_pull_external', 'player_contact'
    create_user
    @master = create_master
    @player_contact = @master.player_contacts.create! data: '(617)123-1234 b', rec_type: :phone, rank: 10
    @al = create_al_for_resource_name(res.resource_name, master: @master)
    expect(@al.master_id).to eq @master.id
    setup_access @al.resource_name, resource_type: :activity_log_type, access: :create, user: @user
  end

  it 'pulls xml from a url' do
    config = {
      this1: {
        data_field: 'notes',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=14760269&retmode=xml',
          format: 'xml'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.notes).to be_present
    expect(@al.notes).to start_with('{"PubmedArticleSet"=>{"PubmedArticle"=>')
  end

  it 'pulls xml from a url and saves to a JSON field' do
    config = {
      this1: {
        data_field: 'result_json',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=14760269&retmode=xml',
          format: 'xml'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.result_json).to be_present
    expect(@al.result_json.dig('PubmedArticleSet', 'PubmedArticle')).to be_present
  end

  it 'pulls json from a url' do
    config = {
      this1: {
        data_field: 'notes',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=14760269&retmode=json',
          format: 'json'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.notes).to be_present
    expect(@al.notes).to start_with('{"header"=>{"type"=>')
  end

  it 'posts query string to a url' do
    config = {
      this1: {
        data_field: 'notes',
        data_field_format: 'json',
        method: 'post',
        to: {
          url: "#{api_uri}#{client_auth_url}",
          format: 'json'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.notes).to be_present
    expect(@al.notes).to eq '{"access_token":"123123123-ad12-1234-99ce-893645:ab","token_type":"bearer","expires_in":3559,"scope":"rspecemail@test.tst"}'
  end

  it 'saves result to a local variable for use in another request' do
    config = {
      this1: {
        local_data: 'identity',
        method: 'post',
        to: {
          url: "#{api_uri}#{client_auth_url}",
          format: 'json'
        }
      },
      this2: {
        data_field: 'notes',
        data_field_format: 'json',
        if: {
          all: {
            this: {
              save_trigger_results: {
                element: 'identity_http_response_code',
                value: 200
              }
            }
          }
        },
        from: {
          url: "#{api_uri}/rest/v1/campaigns/1081.json?access_token={{save_trigger_results.identity.access_token}}",
          format: 'json'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.notes).to be_present
    dnotes = JSON.parse(@al.notes)
    expect(dnotes['result'].first['name']).to eq 'Annual Revenue'
  end

  it 'posts data' do
    lead_email = 'phil-test12@consected.com'

    config = {
      this1: {
        local_data: 'identity',
        method: 'post',
        to: {
          url: "#{api_uri}#{client_auth_url}",
          format: 'json'
        }
      },
      this2: {
        data_field: 'notes',
        data_field_format: 'json',
        local_data: 'post_response',
        method: 'post',
        if: {
          all: {
            this: {
              save_trigger_results: {
                element: 'identity_http_response_code',
                value: 200
              }
            }
          }
        },
        to: {
          url: "#{api_uri}/rest/v1/leads/push.json?access_token={{save_trigger_results.identity.access_token}}",
          format: 'json',
          headers: {
            'Content-Type': 'application/json'
          }
        },
        post_data: {
          programName: 'HCI Participant Import',
          lookupField: 'email',
          source: 'HCIQ Zeus',
          reason: 'Changed status',
          input: [
            {
              email: lead_email,
              firstName: 'Test FN',
              lastName: 'Test LN',
              hCIStage: 'Invitation Email',
              hCIStageUpdatedAt: 'now()',
              hCIQLink: 'https://consected.com'
            }
          ]
        },
        success_if: {
          all: {
            this: {
              save_trigger_results: {
                element: 'post_response.result.first.status',
                condition: '= ANY REV',
                value: ['updated', 'added']
              }
            }
          }
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.notes).to be_present
    dnotes = JSON.parse(@al.notes)
    expect(dnotes['result'].first['status']).to eq 'updated'

    expect(@al.save_trigger_results['post_response_http_response_code']).to eq 200
    expect(@al.save_trigger_results['post_response_success_if_res']).to be true
  end

  it 'pulls json from a url and saves to a JSON field' do
    config = {
      this1: {
        data_field: 'result_json',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&id=14760269&retmode=json',
          format: 'json'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)
    @trigger.perform

    expect(@al.result_json).to be_present
    expect(@al.result_json.dig('header', 'type')).to be_present
  end

  it 'fails to pull from a bad url' do
    config = {
      this1: {
        data_field: 'notes',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/404page',
          format: 'json'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)

    expect do
      @trigger.perform
    end.to raise_error(FphsException, "get external data: failed request with code '404' from url https://eutils.ncbi.nlm.nih.gov/404page")
  end

  it 'fails to pull from a bad url but the failure can be whitelisted, and the result is saved to a field' do
    config = {
      this1: {
        data_field: 'notes',
        response_code_field: 'select_result',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/404page',
          format: 'json',
          allow_response_codes: [404]
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)

    expect do
      @trigger.perform
    end.not_to raise_error

    expect(@al.select_result).to eq '404'
  end

  it 'fails if the content is blank' do
    config = {
      this1: {
        data_field: 'notes',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/blank',
          format: 'json'
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)

    expect do
      @trigger.perform
    end.to raise_error(FphsException, 'get external data: empty content received from https://eutils.ncbi.nlm.nih.gov/blank')
  end

  it 'allows content to be blank if allow_empty_result option set' do
    config = {
      this1: {
        data_field: 'notes',
        from: {
          url: 'https://eutils.ncbi.nlm.nih.gov/blank',
          format: 'json',
          allow_empty_result: true
        }
      }
    }

    @trigger = SaveTriggers::PullExternalData.new(config, @al)

    expect do
      @trigger.perform
    end.not_to raise_error
  end
end
