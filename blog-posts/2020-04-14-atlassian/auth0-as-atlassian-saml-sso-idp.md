---
published: false
title: 'Atlassian SAML SSO with Auth0 IdP'
cover_image: 
description: '[uth0 as SAML 2.0 SSO IdP for Atlassian'
tags: auth0, atlassian, saml, idp
series:
canonical_url:
---

# Atlassian SAML SSO with Auth0 IdP
In this article we'll look at how to configure [Auth0](https://www.auth0.com) as SAML 2.0 SSO IdP for Atlassian.

## Prerequisite
Inside your [Atlassian Organisation](https://admin.atlassian.com) you should have:
    
1. A verified domain  
2. [Atlassian Access](https://www.atlassian.com/software/access)  

![Atlassian Access Cloud Installed](./assets/00-atlassian-prerequisite-access.png)


## Setup

### Step 1. Auth0 IdP Client
Create a "Regular Web Application in Auth0"
   
![01-create-rwa-app](./assets/01-create-rwa-app.png)

### Step 2. Add Connections to your App
Make sure that correct set of Auth0 connections are associated to your IdP app.

![02-app-connections](./assets/02-app-connections.png)

### Step 3. Enable SAML2 Addon
Go to application's Addons tab and enable *SAML2 Web App*.

![03-saml2-addon](./assets/03-saml2-addon.png)

### Step 4. IdP Metadata
Go to *Usage* section in addon configuration. Here you find information to populate SAML metadata in Atlassian Access.

 ![04-addon-usage](./assets/04-addon-usage.png)

### Step 5. Add SAML Connection in Atlassian
In [Atlassian Admin](https://admin.atlassian.com) dashboard, go to `Organization > Security > SAML single sign-on`

![05-add-saml](./assets/05-add-saml.png)

### Step 6. Populate Configuration
Copy configs from addon usage page (step 4) to SAML configuration.

* `Identity provider Entity ID` => `urn:TENANT.auth0.com`
* `Identity provider SSO URL` => `https://TENANT.auth0.com/samlp/APP_ID`
* `Public x509 certificate` => Your tenant's `/pem` location https://TENANT.auth0.com/pem
 
![06-config-saml](./assets/06-config-saml.png)

### Step 7. Get SP Assertion Consumer Service URL
Once configuration saves, you'll see a summary page, copy `SP Assertion Consumer Service URL` 

![07-ACS](./assets/07-idp-url.png)

### Step 8. Configure Application Callback URL in Auth0 SAML2 Addon
Go back to [Auth0 dashboard](https://manage.auth0.com) for your application's SAML2 addon setup tab and
paste:
* `SP Assertion Consumer Service URL` => `Application Callback URL`

And populate metadata mapping file into `Settings` section and *Save*

```json
{
  "mappings": {
    "user_id": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier",
    "given_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
    "family_name": "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
  },
  "nameIdentifierProbes": [
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier",
    "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  ],
  "nameIdentifierFormat": "urn:oasis:names:tc:SAML:2.0:nameid-format:email"
}
``` 

![08-addon-settings](./assets/08-settings.png)

### Step 9. Try Sign in with Verified Domain Email
Visit [id.atlassian.com](https://id.atlassian.com/) and login with a `user@your-verified-domain.com`

![09-try-with-email](./assets/09-try-with-email.png)

### Step 10. Login with SAML IdP and return to Atlassian

![10-success](./assets/10-success.png)