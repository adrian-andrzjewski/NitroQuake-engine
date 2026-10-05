<#
.SYNOPSIS
    The build selector table: one ordered specification of every selector.

.DESCRIPTION
    Each entry declares, for one selector parameter:

      Param       the parameter name on build-dos.ps1
      Manifest    the key it is echoed under in the build manifest
      Suffix      value -> profile-suffix token. A value with no entry emits no
                  token, which is how a selector that is 'on' by default stays out
                  of the output directory name.
      C           value -> -D defines added to the C compiler flags
      Asm         value -> -D defines added to the assembler flags
      SelectsAsm  True when choosing the non-'c' value makes the hand-written
                  assembly live. This drives which .s files are compiled at all.

    Five consumers read this table, and they used to be five hand-written copies
    of the same knowledge:

      1. the profile suffix, and therefore the output directory name
      2. the C flag list
      3. the assembly flag list
      4. which .s files are compiled
      5. the expected active-assembly count, which is what the inventory pin checks

    They had drifted. For instance asm486_experiments.s is excluded by name in one
    place and by an implementation-selector test in two others, and the count that
    the pin compares was computed from a fourth, slightly different list. A selector
    added to three of the four and missed in the fourth would produce a build whose
    inventory silently disagreed with the pin.

    ORDER IS PART OF THE CONTRACT. tools\golden\build-flags-i486.json and
    build-flags-i386.json compare the resolved suffix string and both flag arrays
    element by element, so this table is written in the order the flags and the
    tokens have always appeared. Adding an entry in the wrong place does not fail
    loudly at the point of the mistake; it fails test-build-dos.py, which is the
    point of that pin.

.NOTES
    Every value a ValidateSet allows must appear in Suffix, C and Asm, or be
    deliberately absent from Suffix. A value that appears in none of them is
    silently inert, which is the failure this table makes visible.
#>

# The C implementations that have hand-written assembly behind them. Selecting 'asm'
# on any of these is what makes the .s files part of the build; see SelectsAsm.
$script:AssemblyBackedImplementations = @(
    'MemoryImplementation',
    'FillRectImplementation',
    'ZPointImplementation',
    'SkySpanImplementation',
    'WarpScreenImplementation',
    'SolidSurfaceImplementation',
    'TurbulentScanImplementation',
    'TextureAxisImplementation',
    'SurfaceCacheImplementation',
    'SurfaceDrawImplementation',
    'SurfaceZGradientImplementation',
    'SurfaceGradientImplementation',
    'SurfaceDispatcherImplementation',
    'MipLevelImplementation',
    'TextureAnimationImplementation',
    'LightMapNormalizeImplementation',
    'LightMapStylesImplementation',
    'FusedLightMapImplementation',
    'DynamicLightImplementation',
    'DynamicLightOrchestrationImplementation',
    'DlightContributesImplementation',
    'LightMapBuildImplementation',
    'BspPlaneDotImplementation',
    'BspClipImplementation',
    'RenderWorldImplementation',
    'RenderFaceImplementation',
    'RenderBmodelFaceImplementation',
    'BmodelPolygonClipImplementation',
    'SolidClippedSubmodelPolygonsImplementation',
    'SubmodelPolygonsImplementation',
    'EdgeDrawingImplementation',
    'ScanEdgesImplementation',
    'EdgeListMaintenanceImplementation',
    'BackwardSpansImplementation',
    'EfragStoreImplementation',
    'EmitCachedEdgeImplementation',
    'RenderPolyImplementation',
    'AliasBBoxProjectImplementation',
    'AliasTransformFinalImplementation'
)

$script:SelectorTable = @(

    # ---- the architecture token, which leads the suffix ------------------------
    # Not a normal selector: it is emitted only for the non-default target, so the
    # i486 output directories keep the exact names they have always had. The token
    # is 'i386', not the 'march386' used by the reverted 2026-10-03 experiment, so a
    # stale directory from that experiment cannot be mistaken for this target.
    @{
        Param         = 'CpuTarget'
        Manifest      = 'cpuTarget'
        ArchToken     = @{ 'i386' = 'i386' }
        Suffix        = @{}
        C             = @{ 'i386' = @('TARGET_I386') }
        Asm           = @{ 'i386' = @('TARGET_I386') }
        SelectsAsm    = $false
        Note          = 'TARGET_I386 is also defined for the C sources, below, so one spelling works in both languages under -x assembler-with-cpp.'
    }

    @{
        Param      = 'OptimizationProfile'
        Manifest   = 'optimizationProfile'
        Suffix     = @{ 'baseline' = 'baseline' }
        C          = @{}
        Asm        = @{}
        SelectsAsm = $false
    }

    @{
        Param      = 'TextureAxisCacheEntries'
        Manifest   = 'textureAxisCacheEntries'
        # Only a non-default size is named, so the default leaves the suffix alone.
        Suffix     = @{ '64' = 'cache64'; '128' = 'cache128' }
        # No C entry beyond the empty map: -DD_TEXAXIS_CACHE_SIZE is positional in
        # build-dos.ps1's base flag list, and emitting it from here as well would
        # define it twice.
        C          = @{}
        Asm        = @{}
        SelectsAsm = $false
    }

    # ---- the c-versus-asm implementation selectors ---------------------------
    # Each emits its token when 'asm' is selected, defines the feature macro for
    # both languages, and -- because it has assembly behind it -- makes the .s
    # files live. The manifest echo is the parameter name minus the
    # 'Implementation' suffix, lower-cased, except where the table says otherwise.

    @{
        Param      = 'MemoryImplementation'
        Manifest   = 'memoryImplementation'
        Suffix     = @{ 'asm' = 'memasm' }
        C          = @{ 'asm' = @('ASM486_RUNTIME_MEMOPS') }
        Asm        = @{}
        SelectsAsm = $true
    }

    @{
        Param      = 'FillRectImplementation'
        Manifest   = 'fillRectImplementation'
        Suffix     = @{ 'asm' = 'fillrectasm' }
        C          = @{ 'asm' = @('ASM486_FILLRECT') }
        Asm        = @{ 'asm' = @('ASM486_FILLRECT') }
        SelectsAsm = $true
    }

    @{
        Param      = 'ZPointImplementation'
        Manifest   = 'zPointImplementation'
        Suffix     = @{ 'asm' = 'zpointasm' }
        C          = @{ 'asm' = @('ASM486_ZPOINT') }
        Asm        = @{ 'asm' = @('ASM486_ZPOINT') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SkySpanImplementation'
        Manifest   = 'skySpanImplementation'
        Suffix     = @{ 'asm' = 'skyasm' }
        C          = @{ 'asm' = @('ASM486_SKY_SPAN') }
        Asm        = @{ 'asm' = @('ASM486_SKY_SPAN') }
        SelectsAsm = $true
    }

    @{
        Param      = 'WarpScreenImplementation'
        Manifest   = 'warpScreenImplementation'
        Suffix     = @{ 'asm' = 'warpasm' }
        C          = @{ 'asm' = @('ASM486_WARP_SCREEN') }
        Asm        = @{ 'asm' = @('ASM486_WARP_SCREEN') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SolidSurfaceImplementation'
        Manifest   = 'solidSurfaceImplementation'
        Suffix     = @{ 'asm' = 'solidasm' }
        C          = @{ 'asm' = @('ASM486_SOLID_SURFACE') }
        Asm        = @{ 'asm' = @('ASM486_SOLID_SURFACE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'TextureAxisImplementation'
        Manifest   = 'textureAxisImplementation'
        Suffix     = @{ 'asm' = 'axisasm' }
        C          = @{ 'asm' = @('ASM486_TEXTURE_AXIS_CACHE') }
        Asm        = @{}
        SelectsAsm = $true
    }

    @{
        Param      = 'SurfaceCacheImplementation'
        Manifest   = 'surfaceCacheImplementation'
        Suffix     = @{ 'asm' = 'surfaceasm' }
        C          = @{ 'asm' = @('ASM486_SURFACE_CACHE_CHECK') }
        Asm        = @{ 'asm' = @('ASM486_SURFACE_CACHE_CHECK') }
        SelectsAsm = $true
    }

    @{
        Param      = 'MipLevelImplementation'
        Manifest   = 'mipLevelImplementation'
        Suffix     = @{ 'asm' = 'mipasm' }
        C          = @{ 'asm' = @('ASM486_MIP_LEVEL') }
        Asm        = @{ 'asm' = @('ASM486_MIP_LEVEL') }
        SelectsAsm = $true
    }

    @{
        Param      = 'TurbulentImplementation'
        Manifest   = 'turbulentImplementation'
        Suffix     = @{ 'c' = 'turbc'; 'asm' = 'turbasm' }
        C          = @{ 'c' = @('ASM486_TURBULENT_C') }
        # 'stosb' is the default and emits no token, so it is absent from Suffix;
        # the C selector's define also reaches the assembler so a selected outer
        # scan can call the matching inner-loop reference.
        Asm        = @{
            'c'     = @('ASM486_TURBULENT_C')
            'stosb' = @('ASM486_TURBULENT_STOSB')
        }
        SelectsAsm = $false
    }

    @{
        Param      = 'TurbulentScanImplementation'
        Manifest   = 'turbulentScanImplementation'
        Suffix     = @{ 'asm' = 'turbscan' }
        C          = @{ 'asm' = @('ASM486_TURBULENT_SCAN') }
        Asm        = @{ 'asm' = @('ASM486_TURBULENT_SCAN') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SurfaceDrawImplementation'
        Manifest   = 'surfaceDrawImplementation'
        Suffix     = @{ 'asm' = 'surfacedrawasm' }
        C          = @{ 'asm' = @('ASM486_SURFACE_DRAW') }
        Asm        = @{ 'asm' = @('ASM486_SURFACE_DRAW') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SurfaceZGradientImplementation'
        Manifest   = 'surfaceZGradientImplementation'
        Suffix     = @{ 'asm' = 'surfacezasm' }
        C          = @{ 'asm' = @('ASM486_SURFACE_ZGRADIENTS') }
        Asm        = @{ 'asm' = @('ASM486_SURFACE_ZGRADIENTS') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SurfaceGradientImplementation'
        Manifest   = 'surfaceGradientImplementation'
        Suffix     = @{ 'asm' = 'surfacegradasm' }
        C          = @{ 'asm' = @('ASM486_SURFACE_GRADIENTS') }
        Asm        = @{ 'asm' = @('ASM486_SURFACE_GRADIENTS') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SurfaceDispatcherImplementation'
        Manifest   = 'surfaceDispatcherImplementation'
        Suffix     = @{ 'asm' = 'surfacesasm' }
        C          = @{ 'asm' = @('ASM486_SURFACE_DISPATCH') }
        Asm        = @{ 'asm' = @('ASM486_SURFACE_DISPATCH') }
        SelectsAsm = $true
    }

    # ---- texture spans --------------------------------------------------------
    @{
        Param      = 'TextureSpanStores'
        Manifest   = 'textureSpanStores'
        # 'word' is the retained default and emits no token.
        Suffix     = @{ 'byte' = 'spanbyte'; 'dword' = 'spandword'; 'loop' = 'spanloop'; 'stosw' = 'spanstosw' }
        C          = @{}
        # stosw needs both: the word-store code path and the stosw store sequence.
        Asm        = @{
            'word'  = @('ASM486_SPAN16_WORD_STORES')
            'stosw' = @('ASM486_SPAN16_WORD_STORES', 'ASM486_SPAN16_WORD_STOS')
            'dword' = @('ASM486_SPAN16_DWORD_STORES')
            'loop'  = @('ASM486_SPAN16_LOOP_STOSB')
        }
        SelectsAsm = $false
    }

    @{
        Param      = 'TextureSpanTailStores'
        Manifest   = 'textureSpanTailStores'
        Suffix     = @{ 'word' = 'spantailword' }
        C          = @{}
        Asm        = @{ 'word' = @('ASM486_SPAN16_TAIL_WORD_STORES') }
        SelectsAsm = $false
    }

    @{
        Param      = 'TextureSpanRowPath'
        Manifest   = 'textureSpanRowPath'
        Suffix     = @{ 'norowcross' = 'spannorow' }
        C          = @{}
        Asm        = @{ 'norowcross' = @('ASM486_SPAN16_NO_ROW_CROSS') }
        SelectsAsm = $false
    }

    @{
        Param      = 'TextureSpanLoadOrder'
        Manifest   = 'textureSpanLoadOrder'
        Suffix     = @{ 'loadfirst' = 'spanloadfirst' }
        C          = @{}
        Asm        = @{ 'loadfirst' = @('ASM486_SPAN16_LOAD_FIRST') }
        SelectsAsm = $false
    }

    @{
        Param      = 'TextureSpanAddressing'
        Manifest   = 'textureSpanAddressing'
        Suffix     = @{ 'branch' = 'spanaddrbranch' }
        C          = @{}
        Asm        = @{ 'branch' = @('ASM486_SPAN16_BRANCH_ADDRESS') }
        SelectsAsm = $false
    }

    @{
        Param      = 'AliasSpanAddressing'
        Manifest   = 'aliasSpanAddressing'
        Suffix     = @{ 'branch' = 'aliasspanaddrbranch' }
        C          = @{}
        Asm        = @{ 'branch' = @('ASM486_ALIAS_SPAN_BRANCH_ADDRESS') }
        SelectsAsm = $false
    }

    @{
        Param      = 'ZSpanNegativeUnroll'
        Manifest   = 'zSpanNegativeUnroll'
        # 'control' resolves to the four-times unroll, so both values are named.
        Suffix     = @{ 'control' = 'zneg4'; 'unroll8' = 'zneg8' }
        C          = @{}
        Asm        = @{ 'unroll8' = @('ASM486_ZSPAN_NEG_UNROLL8') }
        SelectsAsm = $false
    }

    @{
        Param      = 'SurfaceBlockMip0Rows'
        Manifest   = 'surfaceBlockMip0Rows'
        Suffix     = @{ 'unroll4' = 'surf0rows4'; 'unroll8' = 'surf0rows8'; 'unroll16' = 'surf0rows16' }
        C          = @{}
        Asm        = @{
            'unroll4'  = @('ASM486_SURF8_MIP0_ROWS4')
            'unroll8'  = @('ASM486_SURF8_MIP0_ROWS8')
            'unroll16' = @('ASM486_SURF8_MIP0_ROWS16')
        }
        SelectsAsm = $false
    }

    @{
        Param      = 'SurfaceBlockMip0HorizontalFlat'
        Manifest   = 'surfaceBlockMip0HorizontalFlat'
        Suffix     = @{ 'fast' = 'surf0hflat' }
        C          = @{}
        Asm        = @{ 'fast' = @('ASM486_SURF8_MIP0_HORIZONTAL_FLAT') }
        SelectsAsm = $false
    }

    @{
        Param      = 'SurfaceBlockMip1Rows'
        Manifest   = 'surfaceBlockMip1Rows'
        Suffix     = @{ 'unroll8' = 'surf1rows8' }
        C          = @{}
        Asm        = @{ 'unroll8' = @('ASM486_SURF8_MIP1_ROWS8') }
        SelectsAsm = $false
    }

    @{
        Param      = 'SurfaceBlockMip1HorizontalFlat'
        Manifest   = 'surfaceBlockMip1HorizontalFlat'
        Suffix     = @{ 'fast' = 'surf1hflat' }
        C          = @{}
        Asm        = @{ 'fast' = @('ASM486_SURF8_MIP1_HORIZONTAL_FLAT') }
        SelectsAsm = $false
    }

    @{
        # Only has an effect when the mip-1 flat path is on, which is why the
        # default is 'hoist' rather than 'control'.
        Param      = 'SurfaceBlockMip1IndexHoist'
        Manifest   = 'surfaceBlockMip1IndexHoist'
        Suffix     = @{ 'hoist' = 'surf1hflatidxhoist' }
        C          = @{}
        Asm        = @{ 'hoist' = @('ASM486_SURF8_MIP1_INDEX_HOIST') }
        SelectsAsm = $false
    }

    # ---- dead-scratch probes --------------------------------------------------
    # Measurement only, never a candidate. 'control' is the release path and must
    # assemble instruction-for-instruction identically, so it emits nothing.

    @{
        Param      = 'EdgeScanProbe'
        Manifest   = 'edgeScanProbe'
        # The probe value becomes the token, uppercased into one -D per value,
        # matching the #ifdef form. gas macros are not C macros and #error is inert
        # under -x assembler-with-cpp, so the define is the only reliable selector.
        Suffix     = @{
            'entry' = 'edgescanprobeentry'; 'step' = 'edgescanprobestep'
            'trailing' = 'edgescanprobetrailing'; 'emit' = 'edgescanprobeemit'
            'insert' = 'edgescanprobeinsert'; 'sort' = 'edgescanprobesort'
            'newtop' = 'edgescanprobenewtop'; 'leadin' = 'edgescanprobeleadin'
            'insertexit' = 'edgescanprobeinsertexit'
        }
        C          = @{}
        Asm        = @{
            'entry' = @('EDGE_SCAN_PROBE_ENTRY'); 'step' = @('EDGE_SCAN_PROBE_STEP')
            'trailing' = @('EDGE_SCAN_PROBE_TRAILING'); 'emit' = @('EDGE_SCAN_PROBE_EMIT')
            'insert' = @('EDGE_SCAN_PROBE_INSERT'); 'sort' = @('EDGE_SCAN_PROBE_SORT')
            'newtop' = @('EDGE_SCAN_PROBE_NEWTOP'); 'leadin' = @('EDGE_SCAN_PROBE_LEADIN')
            'insertexit' = @('EDGE_SCAN_PROBE_INSERTEXIT')
        }
        SelectsAsm = $false
    }

    @{
        Param      = 'SpanSetupProbe'
        Manifest   = 'spanSetupProbe'
        Suffix     = @{ 'setup' = 'spansetupsetup' }
        C          = @{}
        Asm        = @{ 'setup' = @('ASM486_SPAN_SETUP_PROBE_SETUP') }
        SelectsAsm = $false
    }

    @{
        # $-O3 deletes a dead store, so this probe accumulates into a reported
        # global instead of being discarded.
        Param      = 'RenderFaceProbe'
        Manifest   = 'renderFaceProbe'
        Suffix     = @{ 'prologue' = 'rfprobeprologue'; 'edgeval' = 'rfprobeedgeval' }
        C          = @{
            'prologue' = @('ASM486_RENDERFACE_PROBE', 'ASM486_RENDERFACE_PROBE_PROLOGUE')
            'edgeval'  = @('ASM486_RENDERFACE_PROBE', 'ASM486_RENDERFACE_PROBE_EDGEVAL')
        }
        Asm        = @{}
        SelectsAsm = $false
    }

    @{
        Param      = 'AliasGlueProbe'
        Manifest   = 'aliasGlueProbe'
        Suffix     = @{ 'setup' = 'agprobesetup' }
        C          = @{ 'setup' = @('ASM486_ALIAS_GLUE_PROBE', 'ASM486_ALIAS_GLUE_PROBE_SETUP') }
        Asm        = @{}
        SelectsAsm = $false
    }

    # ---- the alias path -------------------------------------------------------

    @{
        Param      = 'AliasProjectImplementation'
        Manifest   = 'aliasProjectImplementation'
        Suffix     = @{ 'c' = 'aliasc' }
        C          = @{ 'asm' = @('ASM486_ALIAS_PROJECT') }
        Asm        = @{ 'asm' = @('ASM486_ALIAS_PROJECT') }
        SelectsAsm = $false
    }

    @{
        Param      = 'AliasBBoxProjectImplementation'
        Manifest   = 'aliasBBoxProjectImplementation'
        Suffix     = @{ 'c' = 'aliasbboxc' }
        C          = @{ 'asm' = @('ASM486_ALIAS_BBOX_PROJECT') }
        Asm        = @{}
        SelectsAsm = $true
    }

    @{
        Param      = 'AliasTransformFinalImplementation'
        Manifest   = 'aliasTransformFinalImplementation'
        Suffix     = @{ 'c' = 'aliastransformc' }
        C          = @{ 'asm' = @('ASM486_ALIAS_TRANSFORM_FINAL') }
        Asm        = @{}
        SelectsAsm = $true
    }

    @{
        Param      = 'AliasPrepareImplementation'
        Manifest   = 'aliasPrepareImplementation'
        Suffix     = @{ 'local' = 'aliaslocal'; 'asm' = 'aliasprepareasm' }
        C          = @{
            'local' = @('ASM486_ALIAS_PREPARE_LOCAL')
            'asm' = @('ASM486_ALIAS_PREPARE')
        }
        Asm        = @{ 'asm' = @('ASM486_ALIAS_PREPARE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'AliasClipImplementation'
        Manifest   = 'aliasClipImplementation'
        Suffix     = @{ 'asm' = 'aliasclipasm' }
        C          = @{ 'asm' = @('ASM486_ALIAS_CLIP') }
        Asm        = @{ 'asm' = @('ASM486_ALIAS_CLIP') }
        SelectsAsm = $true
    }

    @{
        Param      = 'AliasClipZImplementation'
        Manifest   = 'aliasClipZImplementation'
        Suffix     = @{ 'asm' = 'aliasclipzasm' }
        C          = @{ 'asm' = @('ASM486_ALIAS_CLIP_Z') }
        Asm        = @{ 'asm' = @('ASM486_ALIAS_CLIP_Z') }
        SelectsAsm = $true
    }

    @{
        Param      = 'AliasMatrixCompositionImplementation'
        Manifest   = 'aliasMatrixCompositionImplementation'
        Suffix     = @{ 'special' = 'aliasmatrixspecial' }
        C          = @{ 'special' = @('ASM486_ALIAS_MATRIX_COMPOSE') }
        Asm        = @{}
        SelectsAsm = $false
    }

    # ---- lighting -------------------------------------------------------------

    @{
        Param      = 'TextureAnimationImplementation'
        Manifest   = 'textureAnimationImplementation'
        Suffix     = @{ 'c' = 'textureanimc' }
        C          = @{ 'asm' = @('ASM486_TEXTURE_ANIMATION') }
        Asm        = @{ 'asm' = @('ASM486_TEXTURE_ANIMATION') }
        SelectsAsm = $true
    }

    @{
        Param      = 'LightMapNormalizeImplementation'
        Manifest   = 'lightMapNormalizeImplementation'
        Suffix     = @{ 'c' = 'lightmapc' }
        C          = @{ 'asm' = @('ASM486_LIGHTMAP_NORMALIZE') }
        Asm        = @{ 'asm' = @('ASM486_LIGHTMAP_NORMALIZE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'LightMapStylesImplementation'
        Manifest   = 'lightMapStylesImplementation'
        Suffix     = @{ 'asm' = 'lightmapstylesasm' }
        C          = @{ 'asm' = @('ASM486_LIGHTMAP_STYLES') }
        Asm        = @{ 'asm' = @('ASM486_LIGHTMAP_STYLES') }
        SelectsAsm = $true
    }

    @{
        Param      = 'FusedLightMapImplementation'
        Manifest   = 'fusedLightMapImplementation'
        Suffix     = @{ 'asm' = 'fusedlightmapasm' }
        C          = @{ 'asm' = @('ASM486_FUSED_LIGHTMAP') }
        Asm        = @{ 'asm' = @('ASM486_FUSED_LIGHTMAP') }
        SelectsAsm = $true
    }

    @{
        Param      = 'DynamicLightImplementation'
        Manifest   = 'dynamicLightImplementation'
        Suffix     = @{ 'asm' = 'dlightasm' }
        C          = @{ 'asm' = @('ASM486_DYNAMIC_LIGHTS') }
        Asm        = @{ 'asm' = @('ASM486_DYNAMIC_LIGHTS') }
        SelectsAsm = $true
    }

    @{
        Param      = 'DynamicLightOrchestrationImplementation'
        Manifest   = 'dynamicLightOrchestrationImplementation'
        Suffix     = @{ 'asm' = 'dlightorchestrationasm' }
        C          = @{ 'asm' = @('ASM486_DYNAMIC_LIGHT_ORCHESTRATION', 'ASM486_DYNAMIC_LIGHT_PROJECTION') }
        Asm        = @{ 'asm' = @('ASM486_DYNAMIC_LIGHT_ORCHESTRATION', 'ASM486_DYNAMIC_LIGHT_PROJECTION') }
        SelectsAsm = $true
    }

    @{
        Param      = 'DlightContributesImplementation'
        Manifest   = 'dlightContributesImplementation'
        Suffix     = @{ 'asm' = 'dlightcontribasm' }
        C          = @{ 'asm' = @('ASM486_DLIGHT_CONTRIBUTES', 'ASM486_DYNAMIC_LIGHT_PROJECTION') }
        Asm        = @{ 'asm' = @('ASM486_DLIGHT_CONTRIBUTES', 'ASM486_DYNAMIC_LIGHT_PROJECTION') }
        SelectsAsm = $true
    }

    @{
        Param      = 'LightMapBuildImplementation'
        Manifest   = 'lightMapBuildImplementation'
        Suffix     = @{ 'asm' = 'lightmapbuildasm' }
        C          = @{ 'asm' = @('ASM486_LIGHTMAP_BUILD') }
        Asm        = @{ 'asm' = @('ASM486_LIGHTMAP_BUILD') }
        SelectsAsm = $true
    }

    # ---- BSP ------------------------------------------------------------------

    @{
        Param      = 'BspPlaneDotImplementation'
        Manifest   = 'bspPlaneDotImplementation'
        Suffix     = @{ 'asm' = 'bspdotasm' }
        C          = @{ 'asm' = @('ASM486_BSP_PLANE_DOT') }
        Asm        = @{}
        SelectsAsm = $true
    }

    @{
        Param      = 'BspClipImplementation'
        Manifest   = 'bspClipImplementation'
        Suffix     = @{ 'asm' = 'bspclipasm' }
        C          = @{ 'asm' = @('ASM486_BSP_CLIP') }
        Asm        = @{}
        SelectsAsm = $true
    }

    @{
        Param      = 'BspFrameCountImplementation'
        Manifest   = 'bspFrameCountImplementation'
        Suffix     = @{ 'local' = 'bspframecache' }
        C          = @{ 'local' = @('ASM486_BSP_FRAME_COUNT') }
        Asm        = @{}
        SelectsAsm = $false
    }

    @{
        Param      = 'BspWalkImplementation'
        Manifest   = 'bspWalkImplementation'
        Suffix     = @{ 'asm' = 'bspwalkasm' }
        C          = @{ 'asm' = @('ASM486_BSP_WALK') }
        Asm        = @{ 'asm' = @('ASM486_BSP_WALK') }
        SelectsAsm = $true
    }

    @{
        Param      = 'RenderWorldImplementation'
        Manifest   = 'renderWorldImplementation'
        Suffix     = @{ 'asm' = 'renderworldasm' }
        C          = @{ 'asm' = @('ASM486_RENDER_WORLD') }
        Asm        = @{ 'asm' = @('ASM486_RENDER_WORLD') }
        SelectsAsm = $true
    }

    @{
        Param      = 'RenderFaceImplementation'
        Manifest   = 'renderFaceImplementation'
        Suffix     = @{ 'asm' = 'renderfaceasm' }
        C          = @{ 'asm' = @('ASM486_RENDER_FACE') }
        Asm        = @{ 'asm' = @('ASM486_RENDER_FACE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'RenderBmodelFaceImplementation'
        Manifest   = 'renderBmodelFaceImplementation'
        Suffix     = @{ 'asm' = 'bmodelasm' }
        C          = @{ 'asm' = @('ASM486_RENDER_BMODEL_FACE') }
        Asm        = @{ 'asm' = @('ASM486_RENDER_BMODEL_FACE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'BmodelPolygonClipImplementation'
        Manifest   = 'bmodelPolygonClipImplementation'
        Suffix     = @{ 'asm' = 'bmodelclipasm' }
        C          = @{ 'asm' = @('ASM486_BMODEL_POLYGON_CLIP') }
        Asm        = @{ 'asm' = @('ASM486_BMODEL_POLYGON_CLIP') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SolidClippedSubmodelPolygonsImplementation'
        Manifest   = 'solidClippedSubmodelPolygonsImplementation'
        Suffix     = @{ 'asm' = 'bmodelsetupasm' }
        C          = @{ 'asm' = @('ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS') }
        Asm        = @{ 'asm' = @('ASM486_DRAW_SOLID_CLIPPED_SUBMODEL_POLYGONS') }
        SelectsAsm = $true
    }

    @{
        Param      = 'SubmodelPolygonsImplementation'
        Manifest   = 'submodelPolygonsImplementation'
        Suffix     = @{ 'asm' = 'submodelpolysasm' }
        C          = @{ 'asm' = @('ASM486_DRAW_SUBMODEL_POLYGONS') }
        Asm        = @{ 'asm' = @('ASM486_DRAW_SUBMODEL_POLYGONS') }
        SelectsAsm = $true
    }

    @{
        Param      = 'EdgeDrawingImplementation'
        Manifest   = 'edgeDrawingImplementation'
        Suffix     = @{ 'asm' = 'edgedrawasm' }
        C          = @{ 'asm' = @('ASM486_EDGE_DRAWING') }
        Asm        = @{ 'asm' = @('ASM486_EDGE_DRAWING') }
        SelectsAsm = $true
    }

    @{
        Param      = 'ScanEdgesImplementation'
        Manifest   = 'scanEdgesImplementation'
        Suffix     = @{ 'asm' = 'scanedgesasm' }
        C          = @{ 'asm' = @('ASM486_SCAN_EDGES') }
        Asm        = @{ 'asm' = @('ASM486_SCAN_EDGES') }
        SelectsAsm = $true
    }

    @{
        Param      = 'EdgeListMaintenanceImplementation'
        Manifest   = 'edgeListMaintenanceImplementation'
        Suffix     = @{ 'c' = 'edgelistc'; 'asm' = 'edgelistasm' }
        C          = @{
            'legacy' = @()
            'c'   = @('ASM486_EDGE_LIST_C')
            'asm' = @('ASM486_EDGE_LIST')
        }
        Asm        = @{
            'legacy' = @()
            'c'   = @('ASM486_EDGE_LIST_C')
            'asm' = @('ASM486_EDGE_LIST')
        }
        SelectsAsm = $true
    }

    @{
        Param      = 'BackwardSpansImplementation'
        Manifest   = 'backwardSpansImplementation'
        Suffix     = @{ 'asm' = 'backspansasm' }
        C          = @{ 'asm' = @('ASM486_BACKWARD_SPANS') }
        Asm        = @{ 'asm' = @('ASM486_BACKWARD_SPANS') }
        SelectsAsm = $true
    }

    @{
        Param      = 'EfragStoreImplementation'
        Manifest   = 'efragStoreImplementation'
        Suffix     = @{ 'asm' = 'efragstoreasm' }
        C          = @{ 'asm' = @('ASM486_EFRAG_STORE') }
        Asm        = @{ 'asm' = @('ASM486_EFRAG_STORE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'EmitCachedEdgeImplementation'
        Manifest   = 'emitCachedEdgeImplementation'
        Suffix     = @{ 'asm' = 'emitcachedasm' }
        C          = @{ 'asm' = @('ASM486_EMIT_CACHED_EDGE') }
        Asm        = @{ 'asm' = @('ASM486_EMIT_CACHED_EDGE') }
        SelectsAsm = $true
    }

    @{
        Param      = 'RenderPolyImplementation'
        Manifest   = 'renderPolyImplementation'
        Suffix     = @{ 'asm' = 'renderpolyasm' }
        C          = @{ 'asm' = @('ASM486_RENDER_POLY') }
        Asm        = @{ 'asm' = @('ASM486_RENDER_POLY') }
        SelectsAsm = $true
    }

    @{
        Param      = 'GibTrailHorizontalIntegration'
        Manifest   = 'gibTrailHorizontalIntegration'
        Suffix     = @{ 'skipzero' = 'gibskipzero' }
        C          = @{ 'skipzero' = @('ASM486_GIB_TRAIL_SKIP_ZERO_XY') }
        Asm        = @{}
        SelectsAsm = $false
    }
)

<#
.SYNOPSIS
    Read a resolved selector value out of the caller's scope.

.DESCRIPTION
    The table names parameters as strings so it can live in a data file, which means
    the value has to be fetched by name. Set-StrictMode is on, so a name that is
    not a variable is an error rather than $null -- which is the behaviour we want:
    a table entry naming a parameter that does not exist must fail the build, not
    silently do nothing.
#>
function Get-SelectorValue {
    param([Parameter(Mandatory = $true)][string]$Name)
    return (Get-Variable -Name $Name -ValueOnly -ErrorAction Stop)
}

<#
.SYNOPSIS
    The three orders, and the one place that checks them against the table.

.DESCRIPTION
    A selector's effect is emitted in three places, and the three orders are
    different permutations of each other:

      the profile suffix   the order the output-directory name reads in
      the C defines        the order they appear in $cFlags
      the assembly defines the order they appear in $asmFlags

    They differ because each grew for its own reason. The suffix is ordered so the
    directory name is readable. The C defines are ordered so the implementation
    macros follow the shape of the source tree. The assembly defines start with
    TARGET_I386 because that define selects the file-level variants and has to be
    visible before the feature macros.

    So the orders cannot be inferred from each other and are declared here. What
    this file does guarantee is that they cannot silently disagree with the table:
    Assert-SelectorOrdersIsConsistent fails the build if an order names a selector
    that does not exist, if the same selector appears twice in one order, or if a
    selector that contributes a suffix token, a C define or an assembly define is
    missing from the corresponding order.

    That last check is the point. The failure it prevents is a selector added to
    the table and to two of the three orders, which would emit its suffix token and
    its define in one place and silently drop the other -- producing an output
    directory that does not match the binary in it.

    'BUILD:<name>' entries are the two build switches rather than selectors.
    -Benchmark and -Instrumentation are not variants of a source path; they are
    separate compilations. They still need a position, because the golden manifest
    compares the flag arrays element by element and both have sat in the same
    places for a long time.
#>

$script:BuildSwitchDefines = @{
    'BUILD:BENCH486'    = @{ Emit = { $Benchmark };        Define = 'BENCH486' }
    'BUILD:PROFILE486'  = @{ Emit = { $Instrumentation };  Define = 'PROFILE486' }
}

$script:SuffixOrder = @(
    'CpuTarget'
    'OptimizationProfile'
    'TextureAxisCacheEntries'
    'MemoryImplementation'
    'FillRectImplementation'
    'ZPointImplementation'
    'SkySpanImplementation'
    'WarpScreenImplementation'
    'SolidSurfaceImplementation'
    'TextureAxisImplementation'
    'SurfaceCacheImplementation'
    'SurfaceDrawImplementation'
    'SurfaceZGradientImplementation'
    'SurfaceGradientImplementation'
    'SurfaceDispatcherImplementation'
    'MipLevelImplementation'
    'TurbulentImplementation'
    'TurbulentScanImplementation'
    'TextureSpanStores'
    'TextureSpanTailStores'
    'TextureSpanRowPath'
    'TextureSpanLoadOrder'
    'TextureSpanAddressing'
    'AliasSpanAddressing'
    'ZSpanNegativeUnroll'
    'SurfaceBlockMip0Rows'
    'SurfaceBlockMip0HorizontalFlat'
    'SurfaceBlockMip1Rows'
    'SurfaceBlockMip1HorizontalFlat'
    'SurfaceBlockMip1IndexHoist'
    'EdgeScanProbe'
    'SpanSetupProbe'
    'RenderFaceProbe'
    'AliasGlueProbe'
    'AliasProjectImplementation'
    'AliasBBoxProjectImplementation'
    'AliasTransformFinalImplementation'
    'AliasPrepareImplementation'
    'AliasClipImplementation'
    'AliasClipZImplementation'
    'AliasMatrixCompositionImplementation'
    'TextureAnimationImplementation'
    'LightMapNormalizeImplementation'
    'LightMapStylesImplementation'
    'FusedLightMapImplementation'
    'DynamicLightImplementation'
    'DynamicLightOrchestrationImplementation'
    'DlightContributesImplementation'
    'LightMapBuildImplementation'
    'BspPlaneDotImplementation'
    'BspClipImplementation'
    'BspFrameCountImplementation'
    'BspWalkImplementation'
    'RenderWorldImplementation'
    'RenderFaceImplementation'
    'RenderBmodelFaceImplementation'
    'BmodelPolygonClipImplementation'
    'SolidClippedSubmodelPolygonsImplementation'
    'SubmodelPolygonsImplementation'
    'EdgeDrawingImplementation'
    'ScanEdgesImplementation'
    'EdgeListMaintenanceImplementation'
    'BackwardSpansImplementation'
    'EfragStoreImplementation'
    'EmitCachedEdgeImplementation'
    'RenderPolyImplementation'
    'GibTrailHorizontalIntegration'
)

$script:CDefineOrder = @(
    'BUILD:BENCH486'
    'MemoryImplementation'
    'FillRectImplementation'
    'ZPointImplementation'
    'SkySpanImplementation'
    'WarpScreenImplementation'
    'SolidSurfaceImplementation'
    'TextureAxisImplementation'
    'SurfaceCacheImplementation'
    'SurfaceDrawImplementation'
    'SurfaceZGradientImplementation'
    'SurfaceGradientImplementation'
    'SurfaceDispatcherImplementation'
    'MipLevelImplementation'
    'TextureAnimationImplementation'
    'LightMapNormalizeImplementation'
    'LightMapStylesImplementation'
    'FusedLightMapImplementation'
    'DynamicLightImplementation'
    'DynamicLightOrchestrationImplementation'
    'DlightContributesImplementation'
    'LightMapBuildImplementation'
    'BspPlaneDotImplementation'
    'BspClipImplementation'
    'BspFrameCountImplementation'
    'BspWalkImplementation'
    'RenderWorldImplementation'
    'RenderFaceImplementation'
    'RenderBmodelFaceImplementation'
    'BmodelPolygonClipImplementation'
    'SolidClippedSubmodelPolygonsImplementation'
    'SubmodelPolygonsImplementation'
    'EdgeDrawingImplementation'
    'ScanEdgesImplementation'
    'EdgeListMaintenanceImplementation'
    'BackwardSpansImplementation'
    'EfragStoreImplementation'
    'EmitCachedEdgeImplementation'
    'RenderPolyImplementation'
    'GibTrailHorizontalIntegration'
    'AliasBBoxProjectImplementation'
    'AliasTransformFinalImplementation'
    'AliasPrepareImplementation'
    'AliasClipImplementation'
    'AliasClipZImplementation'
    'AliasMatrixCompositionImplementation'
    'TurbulentImplementation'
    'TurbulentScanImplementation'
    'BUILD:PROFILE486'
    'AliasGlueProbe'
    'RenderFaceProbe'
    'AliasProjectImplementation'
    'CpuTarget'
)

$script:AsmDefineOrder = @(
    'CpuTarget'
    'FillRectImplementation'
    'ZPointImplementation'
    'SkySpanImplementation'
    'WarpScreenImplementation'
    'SolidSurfaceImplementation'
    'SurfaceCacheImplementation'
    'SurfaceDrawImplementation'
    'SurfaceZGradientImplementation'
    'SurfaceGradientImplementation'
    'SurfaceDispatcherImplementation'
    'MipLevelImplementation'
    'TextureAnimationImplementation'
    'AliasPrepareImplementation'
    'AliasClipImplementation'
    'AliasProjectImplementation'
    'AliasClipZImplementation'
    'BUILD:PROFILE486'
    'LightMapNormalizeImplementation'
    'LightMapStylesImplementation'
    'FusedLightMapImplementation'
    'DynamicLightImplementation'
    'DynamicLightOrchestrationImplementation'
    'DlightContributesImplementation'
    'LightMapBuildImplementation'
    'BspWalkImplementation'
    'RenderWorldImplementation'
    'RenderFaceImplementation'
    'RenderBmodelFaceImplementation'
    'BmodelPolygonClipImplementation'
    'SolidClippedSubmodelPolygonsImplementation'
    'SubmodelPolygonsImplementation'
    'EdgeDrawingImplementation'
    'ScanEdgesImplementation'
    'EdgeListMaintenanceImplementation'
    'BackwardSpansImplementation'
    'EfragStoreImplementation'
    'EmitCachedEdgeImplementation'
    'RenderPolyImplementation'
    'TurbulentImplementation'
    'TurbulentScanImplementation'
    'TextureSpanStores'
    'TextureSpanRowPath'
    'TextureSpanTailStores'
    'TextureSpanLoadOrder'
    'TextureSpanAddressing'
    'AliasSpanAddressing'
    'ZSpanNegativeUnroll'
    'SurfaceBlockMip0Rows'
    'SurfaceBlockMip0HorizontalFlat'
    'SurfaceBlockMip1Rows'
    'SurfaceBlockMip1HorizontalFlat'
    'SurfaceBlockMip1IndexHoist'
    'EdgeScanProbe'
    'SpanSetupProbe'
)

function Get-SelectorEntry {
    <#
    .SYNOPSIS
        The table entry for a parameter name, or $null for a BUILD: sentinel.
    #>
    param([Parameter(Mandatory = $true)][string]$Name)

    if ($Name.StartsWith('BUILD:')) {
        return $null
    }
    foreach ($selector in $script:SelectorTable) {
        if ($selector.Param -eq $Name) {
            return $selector
        }
    }
    return $null
}

function Assert-SelectorOrdersIsConsistent {
    <#
    .SYNOPSIS
        Fail the build if an order and the table disagree.

    .DESCRIPTION
        Called once, immediately after this file is dot-sourced. Cheap, and it turns
        the silent failure this table exists to prevent into a build error at the
        point of the mistake.
    #>
    [CmdletBinding()]
    param()

    $problems = New-Object System.Collections.Generic.List[string]

    # Every entry must carry every key. A missing key is not caught by the order
    # checks below -- an absent C map simply contributes nothing -- and it fails
    # later, at the consumer, as a strict-mode error about a property that does not
    # exist. Naming the missing key here points at the table entry instead.
    $requiredKeys = @('Param', 'Manifest', 'Suffix', 'C', 'Asm', 'SelectsAsm')
    foreach ($selector in $script:SelectorTable) {
        $label = if ($selector.ContainsKey('Param')) { $selector.Param } else { '<unnamed entry>' }
        foreach ($key in $requiredKeys) {
            if (-not $selector.ContainsKey($key)) {
                $problems.Add("table entry '$label' has no '$key' key.")
            }
        }
    }

    $seenNames = @{}
    foreach ($selector in $script:SelectorTable) {
        if (-not $selector.ContainsKey('Param')) { continue }
        if ($seenNames.ContainsKey($selector.Param)) {
            $problems.Add("the table has two entries for '$($selector.Param)'.")
        }
        $seenNames[$selector.Param] = $true
    }

    foreach ($order in @(
            @{ Name = 'SuffixOrder'; List = $script:SuffixOrder }
            @{ Name = 'CDefineOrder'; List = $script:CDefineOrder }
            @{ Name = 'AsmDefineOrder'; List = $script:AsmDefineOrder })) {

        $seen = @{}
        foreach ($name in $order.List) {
            if ($seen.ContainsKey($name)) {
                $problems.Add("$($order.Name) lists '$name' twice.")
                continue
            }
            $seen[$name] = $true
            if ($name.StartsWith('BUILD:')) {
                if (-not $script:BuildSwitchDefines.ContainsKey($name)) {
                    $problems.Add("$($order.Name) names unknown build switch '$name'.")
                }
                continue
            }
            if ($null -eq (Get-SelectorEntry -Name $name)) {
                $problems.Add("$($order.Name) names '$name', which is not in the selector table.")
            }
        }
    }

    # Every selector that has something to emit must appear in the order that emits
    # it. A selector absent from an order contributes nothing there, silently.
    #
    # Each map is read through ContainsKey rather than as a property. Under
    # Set-StrictMode a property read on a hashtable that lacks the key is a
    # terminating error, so a missing key would abort here with "The property 'C'
    # cannot be found" and the specific problem collected above would never be
    # printed -- which is exactly the confusing failure this function exists to
    # replace.
    foreach ($selector in $script:SelectorTable) {
        $hasSuffix = $selector.ContainsKey('Suffix') -and $selector.Suffix.Count -gt 0
        $hasC = $selector.ContainsKey('C') -and $selector.C.Count -gt 0
        $hasAsm = $selector.ContainsKey('Asm') -and $selector.Asm.Count -gt 0
        if ($hasSuffix -and ($script:SuffixOrder -notcontains $selector.Param)) {
            $problems.Add("$($selector.Param) has suffix tokens but is missing from SuffixOrder.")
        }
        if ($hasC -and ($script:CDefineOrder -notcontains $selector.Param)) {
            $problems.Add("$($selector.Param) has C defines but is missing from CDefineOrder.")
        }
        if ($hasAsm -and ($script:AsmDefineOrder -notcontains $selector.Param)) {
            $problems.Add("$($selector.Param) has assembly defines but is missing from AsmDefineOrder.")
        }
    }

    if ($problems.Count -gt 0) {
        throw ("The selector table and the selector orders disagree:`n  " +
            ($problems -join "`n  ") +
            "`nSee tools\selectors.ps1.")
    }
}
<#
.SYNOPSIS
    The selectors the build manifest echoes from the table, in order.

.DESCRIPTION
    The manifest has always listed its selector fields in the same order as the
    profile suffix, which is a fourth copy of an ordering. Rather than declare it
    again, it is derived: SuffixOrder minus the three selectors the manifest emits
    explicitly, because their keys are not the table's Manifest keys -- cpuTarget is
    already there, and optimizationProfile and textureAxisCacheEntries sit after the
    block as configuration rather than as a source-path variant.

    Assert-SelectorManifestOrderIsConsistent checks that this really is the same set
    the manifest used to carry, so the derivation cannot quietly drop a selector.
#>
$script:ManifestExplicitSelectors = @('CpuTarget', 'OptimizationProfile', 'TextureAxisCacheEntries')

$script:ManifestSelectorOrder = @(
    $script:SuffixOrder | Where-Object { $script:ManifestExplicitSelectors -notcontains $_ }
)

function Assert-SelectorManifestOrderIsConsistent {
    [CmdletBinding()]
    param()

    $problems = New-Object System.Collections.Generic.List[string]

    $expected = New-Object System.Collections.Generic.List[string]
    foreach ($selector in $script:SelectorTable) {
        if ($script:ManifestExplicitSelectors -contains $selector.Param) {
            continue
        }
        $expected.Add($selector.Param)
    }

    $actual = @($script:ManifestSelectorOrder)
    if ($actual.Count -ne $expected.Count) {
        $problems.Add("the manifest echo covers $($actual.Count) selector(s) but the table has $($expected.Count) outside the explicitly-emitted three.")
    }
    foreach ($name in $expected) {
        if ($actual -notcontains $name) {
            $problems.Add("'$name' is in the table but not in the manifest echo order.")
        }
    }
    foreach ($name in $actual) {
        if ($expected -notcontains $name) {
            $problems.Add("'$name' is in the manifest echo order but not in the table.")
        }
    }

    # Two selectors echoing under one manifest key would silently drop one of them.
    $keys = @{}
    foreach ($name in $actual) {
        $entry = Get-SelectorEntry -Name $name
        $key = if ($null -ne $entry -and $entry.ContainsKey('Manifest')) { $entry.Manifest } else { $null }
        if ($null -eq $key) {
            $problems.Add("'$name' has no Manifest key, so the build manifest cannot echo it.")
            continue
        }
        if ($keys.ContainsKey($key)) {
            $problems.Add("'$name' and '$($keys[$key])' both use the manifest key '$key'.")
        }
        $keys[$key] = $name
    }

    if ($problems.Count -gt 0) {
        throw ("The manifest echo order and the selector table disagree:`n  " +
            ($problems -join "`n  ") +
            "`nSee tools\selectors.ps1.")
    }
}
