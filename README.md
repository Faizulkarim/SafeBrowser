# SafeBrowser

# Kahf SafeBrowser Assessment: Ethical Content Filtering with Advanced URL Validation  

## Description  
This is an assessment project for **Kahf**, aimed at developing a browser that ensures ethical and responsible internet usage. The Kahf SafeBrowser leverages a DNS-based filtering system and external validation to block haram content effectively.  

##Video

https://github.com/user-attachments/assets/154ae12a-5a79-4ee2-9f90-7a3e1d934793

---

## Project Purpose  
To provide a secure and principled browsing experience by intercepting user interactions, validating URLs via **high.kahfguard.com**, and ip **51.142.0.102** and blocking inappropriate content based on ethical guidelines.  

---

## Features  
- **Dynamic URL Filtering**:  
  - Every URL accessed via the web view is intercepted and validated using the **high.kahfguard.com**.  
  - Blocks haram or harmful content in real time.  

- **Custom DNS Resolver**:  
  - Filters DNS requests for added security and content validation.  

- **Interactive Browsing**:  
  - Provides feedback on URL validity, ensuring user awareness.  

- **Modern UI**:  
  - Built with SwiftUI for a sleek, user-friendly experience.  

- **Progressive Loading Indicators**:  
  - Displays visual progress for DNS resolution and URL verification.  

---

## Workflow  
1. **User Action**: The user clicks any link or button on the web view.  
2. **URL Interception**: The URL is intercepted before loading.  
3. **Validation**: The URL is sent to **high.kahfguard.com** for content validation.  
4. **Decision**:  
   - **Blocked**: Displays a message about restricted content.  
   - **Allowed**: Proceeds with loading the page.  

---

## Additional Implementation  
### Unit Testing  
Comprehensive unit tests have been written to validate the Program. 
---

## Tech Stack  
- **Swift**: Core application logic and UI design.  
- **SwiftUI**: Modern and responsive user interface framework.  
- **Combine Framework**: Asynchronous URL validation and state updates.  
- **NIO and NIOExtras**: High-performance networking for DNS resolution.  
- **WebKit**: Advanced web rendering and interaction tracking.  
- **XCTest**: Framework used to implement and automate unit tests.  

---

## Installation and Setup 

### Prerequisites  
1. **Xcode**: Ensure you have Xcode 14.0 or later installed.    
3. **Swift Version**: Swift 5.7 or later.  

### Clone the Repository 
git clone https://github.com/username/Kahf-SafeBrowser.git

###Navigate to the Package Dependencies
- In Xcode, click on the project file in the **Project Navigator**.  
- Select the **Package Dependencies** tab under the main project settings.
- If any package dependencies are missing or not resolved:  
 - Re-fetch any existing packages by clicking **File > Packages > Resolve Package Dependencies** in the top menu bar.  



