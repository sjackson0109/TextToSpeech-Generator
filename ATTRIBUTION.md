# Attribution and License Information

## Original Work

This project is derived from and builds upon the excellent foundation provided by:

### **Luca Vitali - AzureTTSVoiceGeneratorGUI (2019)**
- **Repository**: https://github.com/LucaVitali/AzureTTSVoiceGeneratorGUI
- **License**: MIT License
- **Contribution**: Original PowerShell-based TTS application with WPF GUI for Azure Cognitive Services

**Original License Statement:**
```
The MIT License (MIT)

Copyright (c) 2019 Luca Vitali

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Derivative Work

### **Simon Jackson - TextToSpeech Generator v2.0 (2024-2025)**
- **Repository**: https://github.com/sjackson0109/TextToSpeech-Generator
- **License**: MIT License
- **Enhancements and Extensions**:

#### **Major Feature Additions:**
- ✅ **Multi-Provider Support**: Extended from Azure-only to 6 TTS providers:
  - Azure Cognitive Services (enhanced from original)
  - Amazon Polly (new)
  - Google Cloud Text-to-Speech (new)
  - CloudPronouncer (new)
  - Twilio (new)
  - VoiceForge (new)

- ✅ **Advanced Voice Options**: Provider-specific advanced configuration dialogs with:
  - Speech rate, pitch, and volume controls
  - Audio encoding options
  - SSML processing capabilities
  - Custom voice model support

- ✅ **Comprehensive Regional Coverage**:
  - Azure: Expanded from 5 to 58+ regions
  - AWS: Added 32+ regions
  - Google Cloud: Added 35+ regions

- ✅ **Enhanced User Interface**:
  - Dynamic window sizing with SizeToContent
  - Modern dark theme with improved contrast
  - Bulk mode interface with proper control logic
  - Comprehensive API setup guidance
  - Provider-specific validation systems

- ✅ **Configuration Management**:
  - XML-based complete configuration persistence
  - Cross-session settings retention
  - Advanced options storage and retrieval
  - Import/export capabilities

#### **Technical Improvements:**
- Enhanced XAML structure with modular provider sections
- Improved error handling and logging systems
- Dynamic UI control management
- Provider-specific API credential validation
- Comprehensive documentation and user guides

## License Compliance

Both the original work by **Luca Vitali** and the derivative work by **Simon Jackson** are licensed under the **MIT License**, ensuring:

- ✅ **Freedom to Use**: Commercial and non-commercial use permitted
- ✅ **Freedom to Modify**: Full modification and enhancement rights
- ✅ **Freedom to Distribute**: Redistribution with proper attribution
- ✅ **Freedom to Sublicense**: Additional licensing terms allowed

## Attribution Requirements

When using, modifying, or redistributing this software:

1. **Include the LICENSE file** containing both original and derivative work licenses
2. **Preserve attribution** to both Luca Vitali (original) and Simon Jackson (enhancements)
3. **Maintain license notices** in source code headers
4. **Reference original repository** when publicly sharing or documenting

## Acknowledgments

- **Luca Vitali**: Thank you for creating the original foundation and sharing it under the permissive MIT License, enabling community enhancement and growth
- **Microsoft, Amazon, Google, CloudPronouncer, Twilio, VoiceForge**: For providing the TTS APIs that make this application valuable
- **PowerShell and WPF Communities**: For the frameworks and resources that enable rich desktop applications

---

**Last Updated**: October 13, 2025  
**License Compliance**: ✅ Verified MIT License Requirements Met