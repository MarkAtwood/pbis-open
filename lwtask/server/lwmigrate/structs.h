/* Editor Settings: expandtabs and use 4 spaces for indentation
 * ex: set softtabstop=4 tabstop=8 expandtab shiftwidth=4: *
 * -*- mode: c, c-basic-offset: 4 -*- */

/*
 * Copyright Likewise Software    2004-2008
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.  You should have received a copy of the GNU General
 * Public License along with this program.  If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * LIKEWISE SOFTWARE MAKES THIS SOFTWARE AVAILABLE UNDER OTHER LICENSING
 * TERMS AS WELL.  IF YOU HAVE ENTERED INTO A SEPARATE LICENSE AGREEMENT
 * WITH LIKEWISE SOFTWARE, THEN YOU MAY ELECT TO USE THE SOFTWARE UNDER THE
 * TERMS OF THAT SOFTWARE LICENSE AGREEMENT INSTEAD OF THE TERMS OF THE GNU
 * GENERAL PUBLIC LICENSE, NOTWITHSTANDING THE ABOVE NOTICE.  IF YOU
 * HAVE QUESTIONS, OR WISH TO REQUEST A COPY OF THE ALTERNATE LICENSING
 * TERMS OFFERED BY LIKEWISE SOFTWARE, PLEASE CONTACT LIKEWISE SOFTWARE AT
 * license@likewisesoftware.com
 */

/*
 * Copyright (C) Likewise Software. All rights reserved.
 *
 * Module Name:
 *
 *        structs.h
 *
 * Abstract:
 *
 *        Likewise Task Service (LWTASK)
 *
 *        Share Migration Management
 *
 *        Structure Definitions
 *
 * Authors: Sriram Nambakam (snambakam@likewise.com)
 *
 */

typedef struct _LW_TASK_CREDS
{
    krb5_context ctx;
    krb5_ccache  cc;
    PSTR         pszRestoreCache;

    LW_PIO_CREDS pKrb5Creds;

} LW_TASK_CREDS, *PLW_TASK_CREDS;

typedef struct _LW_TASK_FILE
{
    LONG           refCount;

    IO_FILE_HANDLE hFile;

} LW_TASK_FILE, *PLW_TASK_FILE;

typedef struct _LW_TASK_DIRECTORY
{
    PLW_TASK_FILE pParentRemote;
    PLW_TASK_FILE pParentLocal;

    PWSTR         pwszName;

    struct _LW_TASK_DIRECTORY* pNext;
    struct _LW_TASK_DIRECTORY* pPrev;

} LW_TASK_DIRECTORY, *PLW_TASK_DIRECTORY;

typedef struct _LW_SHARE_MIGRATION_COUNTERS
{
    ULONG64 ullNumFolders;
    ULONG64 ullNumFiles;

} LW_SHARE_MIGRATION_COUNTERS, *PLW_SHARE_MIGRATION_COUNTERS;

typedef struct _LW_SHARE_MIGRATION_CONTEXT
{
    pthread_mutex_t  mutex;
    pthread_mutex_t* pMutex;

    PWSTR          pwszServer;

    PLW_TASK_CREDS pRemoteCreds;
    LW_PIO_CREDS   pLocalCreds;

    LW_SHARE_MIGRATION_COUNTERS expected;
    LW_SHARE_MIGRATION_COUNTERS visited;

    PLW_TASK_DIRECTORY pHead;
    PLW_TASK_DIRECTORY pTail;

} LW_SHARE_MIGRATION_CONTEXT;

typedef struct _LW_SHARE_MIGRATION_GLOBALS
{
    BOOLEAN   bNetApiInitialized;
    PWSTR     pwszDefaultSharePath;
    wchar16_t wszRemoteDriverPrefix[32];
    wchar16_t wszDiskDriverPrefix[32];

} LW_SHARE_MIGRATION_GLOBALS, *PLW_SHARE_MIGRATION_GLOBALS;

