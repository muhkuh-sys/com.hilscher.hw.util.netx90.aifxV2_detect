# -*- coding: utf-8 -*-
#-------------------------------------------------------------------------#
#   Copyright (C) 2016 by Christoph Thelen                                #
#   doc_bacardi@users.sourceforge.net                                     #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
#-------------------------------------------------------------------------#


#----------------------------------------------------------------------------
#
# Set up the Muhkuh Build System.
#
SConscript('mbs/SConscript')
Import('atEnv')

# Create a build environment for the Cortex-M4 based netX chips.
env_cortexM4 = atEnv.DEFAULT.CreateEnvironment(['gcc-arm-none-eabi-4.9', 'asciidoc'])
env_cortexM4.CreateCompilerEnv('NETX90', ['arch=armv7', 'thumb'], ['arch=armv7e-m', 'thumb'])

# Build the platform libraries.
SConscript('platform/SConscript')


#----------------------------------------------------------------------------
#
# Get the source code version from the VCS.
#
atEnv.DEFAULT.Version('#targets/version/version.h', 'templates/version.h')
atEnv.DEFAULT.Version('#targets/hboot_snippet.xml', 'templates/hboot_snippet.xml')


#----------------------------------------------------------------------------
#
# Build all files.
#
sources = """
	src/header.c
	src/main.c
"""


# The list of include folders. Here it is used for all files.
astrIncludePaths = ['src', '#platform/src', '#platform/src/lib', '#targets/version']

global PROJECT_VERSION


#
# Build the netX90 snippet.
#
tEnv90 = atEnv.NETX90.Clone()
tEnv90.Append(CPPPATH = astrIncludePaths)
tEnv90.Replace(LDFILE = 'src/netx90/netx90_com_intram.ld')
tSrc90 = tEnv90.SetBuildPath('targets/netx90_com_intram', 'src', sources)
tElf90 = tEnv90.Elf('targets/netx90_com_intram/aifxv2_detect_snippet_netx90_com_intram.elf', tSrc90 + tEnv90['PLATFORM_LIBRARY'])
tTxt90 = tEnv90.ObjDump('targets/netx90_com_intram/aifxv2_detect_snippet_netx90_com_intram.txt', tElf90, OBJDUMP_FLAGS=['--disassemble', '--source', '--all-headers', '--wide'])
tBin90 = tEnv90.ObjCopy('targets/netx90_com_intram/aifxv2_detect_snippet_netx90_com_intram.bin', tElf90)
tTmp90 = tEnv90.GccSymbolTemplate('targets/netx90_com_intram/snippet.xml', tElf90, GCCSYMBOLTEMPLATE_TEMPLATE='targets/hboot_snippet.xml', GCCSYMBOLTEMPLATE_BINFILE=tBin90[0])

# Create the snippet from the parameters.
aArtifactGroupReverse90 = ['com', 'hilscher', 'hw', 'util', 'netx90']
atSnippet90 = {
    'group': '.'.join(aArtifactGroupReverse90),
    'artifact': 'aifxv2_detect',
    'version': PROJECT_VERSION,
    'vcs_id': tEnv90.Version_GetVcsIdLong(),
    'vcs_url': tEnv90.Version_GetVcsUrl(),
    'license': 'GPL-2.0',
    'author_name': 'Muhkuh team',
    'author_url': 'https://github.com/muhkuh-sys',
    'description': 'Read ID from AIFX V2 module available on netX90',
    'categories': ['netx90', 'booting'],
    'parameter': {
        'TARGET_ADDRESS': {'help': 'Address to write to the ID from the connected AIFX V2 module.'}
    }

}
strArtifactPath90 = 'targets/snippets/%s/%s/%s' % ('/'.join(aArtifactGroupReverse90), atSnippet90['artifact'], PROJECT_VERSION)
snippet_netx90_com = tEnv90.HBootSnippet('%s/%s-%s.xml' % (strArtifactPath90, atSnippet90['artifact'], PROJECT_VERSION), tTmp90, PARAMETER=atSnippet90)

# Create the POM file.
tPOM90 = tEnv90.POMTemplate('%s/%s-%s.pom' % (strArtifactPath90, atSnippet90['artifact'], PROJECT_VERSION), 'templates/pom.xml', POM_TEMPLATE_GROUP=atSnippet90['group'], POM_TEMPLATE_ARTIFACT=atSnippet90['artifact'], POM_TEMPLATE_VERSION=atSnippet90['version'], POM_TEMPLATE_PACKAGING='xml')



# Create binaries for verification
test02_netx90_snippet_hbootimage = tEnv90.HBootImage('targets/verification/test02/test02_netx90_snippet_hbootimage.bin', 'verification/test02/test02_netx90_snippet_hbootimage.xml')

