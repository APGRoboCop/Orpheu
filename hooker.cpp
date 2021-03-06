
#include <hooker.h>
#include <cbase.h>

namespace Hooker
{
	HookerCvarRegister* hookerCvarRegister = NULL;

	void HookerCvarRegister::hooker(cvar_t *cvar)
	{
		char *libraryName;

		if (Global::LibrariesCvarToName->retrieve(cvar->name, &libraryName))
		{
			LibrariesManager::addLibrary(libraryName, (void*)cvar);
		}

		hookerCvarRegister->undoPatch();
		g_engfuncs.pfnCVarRegister(cvar);
		hookerCvarRegister->doPatch();
	}

	HookerCvarRegister::HookerCvarRegister()
	{
		createPatch();

		doPatch();
	}

	void HookerCvarRegister::createPatch()
	{
		memcpy((void*)originalBytes, (void*)g_engfuncs.pfnCVarRegister, patchSize);

		patchedBytes[0] = 0xE9;
		*(long*)&patchedBytes[1] = (char*)hooker - (char*)g_engfuncs.pfnCVarRegister - 5;
	}

	void HookerCvarRegister::doPatch()
	{
		if (Memory::ChangeMemoryProtection((void*)g_engfuncs.pfnCVarRegister, patchSize, PAGE_EXECUTE_READWRITE))
		{
			memcpy((void*)g_engfuncs.pfnCVarRegister, (void*)patchedBytes, patchSize);
		}
		else
		{
			Global::ConfigManagerObj->ModuleConfig.append(ke::AString("PATCHING FAILED\n"));
		}
	}

	void HookerCvarRegister::undoPatch()
	{
		memcpy((void*)g_engfuncs.pfnCVarRegister, (void*)originalBytes, patchSize);
	}
}