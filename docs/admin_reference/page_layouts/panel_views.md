# Panel Views

A **Panel View** allows configurable styling of a specific panel within a master record.
The panel can also have CSS applied to its content.

    container:
      rows:
        - cols:
            - label: Participant Summary
              header: |
                ## IPA ID: {_{ids.ipa_id}_}
              
              classes: col-md-24 col-lg-24
              resource: 
                name: activity_log__ipa_assignment_summary
          styles:
            min-height: 10vh

    view_css:
      selectors:
        div.sp-col-inner:
          border: 0
          box-shadow: none
        .sp-main:
          margin: 2% 5%
