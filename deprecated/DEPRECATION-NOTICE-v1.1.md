# DEPRECATION NOTICE

This file (TextToSpeech-Generator-v1.1.ps1) is **DEPRECATED** and maintained only for reference.

## Current Status: LEGACY / DEPRECATED

- **Last Updated**: October 10, 2025
- **Status**: Replaced by modular architecture (v3.2+)
- **Replacement**: Use `StartModularTTS.ps1` instead

## Migration Path

1. **For New Users**: Use `StartModularTTS.ps1` directly
2. **For Existing Users**: Run `MigrateLegacyConfig.ps1` to convert XML to JSON
3. **Configuration**: Edit `config.json` instead of XML files

## Why Deprecated?

- Monolithic architecture replaced with modular design
- Security vulnerabilities addressed in new version
- Performance improvements in modular system
- Better error handling and recovery
- Enterprise-grade features unavailable in legacy version

## Removal Timeline

- **v3.2**: Deprecated, kept for reference
- **v3.3** (Planned): Will be removed from repository
- **v4.0** (Future): Complete removal

## Support

Legacy versions are **no longer supported**. Please migrate to the modular architecture for:
- Security updates
- Bug fixes  
- New features
- Technical support

For migration assistance, see: `docs/MIGRATION.md`