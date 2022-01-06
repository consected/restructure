# Page Layouts

## Introduction

**Page Layouts** provide configuration for the visual layout of various components within an app.

The components that can be configured are:

- [Master Panels](master_panels.md)
- [User Profile](user_profile.md)
- [Navigations](navigations.md)
- [Dashboards](dashboards.md)
- [Content Pages](content_pages.md)
- [Panel Views](panel_views.md)

Administration is provided in [Admin: Page Layouts](/admin/page_layouts)

## Assignment to App Types

Typically, each definition is assigned to an **App Type**. The current *app type* a user is using selects the appropriate definitions to apply.

A special case allows definitions to have a null *app type*, in which case the definition
is available to users irrespective of their current *app type* (i.e. in all *app types*). Typically definitions assigned to an *app type* appear ahead of those with a null *app type*. For definitions
where only a single definition can be used, one with an *app type* will override one
available to all *app types*.

## Contents

- [Detailed Options](detailed_options.md)
