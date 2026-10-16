<script setup lang="ts">
definePageMeta({
  layout: 'empty',
  title: 'Privacy Policy',
  preview: {
    title: 'Privacy Policy',
    description: 'Privacy Policy page',
    categories: ['pages'],
    order: 100,
  },
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <div class="mb-6">
          <BaseHeading
            as="h1"
            size="3xl"
            weight="bold"
            class="text-muted-800 dark:text-white mb-2"
          >
            {{ $t('Privacy Policy') }}
          </BaseHeading>
          <BaseParagraph size="sm" class="text-muted-400">
            {{ $t('Last updated') }}: {{ new Date().toLocaleDateString() }}
          </BaseParagraph>
        </div>

        <!-- Content Card -->
        <BaseCard class="p-8">
          <div class="prose prose-primary dark:prose-invert max-w-none">
            <!-- Introduction -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Introduction') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'Welcome to our CMMS (Computerized Maintenance Management System). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our application.',
                  )
                }}
              </BaseParagraph>
            </section>

            <!-- Information We Collect -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Information We Collect') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'We collect information that you provide directly to us when using our CMMS application, including:',
                  )
                }}
              </BaseParagraph>
              <ul
                class="list-disc pl-6 mb-4 text-muted-600 dark:text-muted-400 space-y-2"
              >
                <li>
                  {{
                    $t('Account information (name, email address, password)')
                  }}
                </li>
                <li>
                  {{
                    $t(
                      'Profile information (job title, department, contact details)',
                    )
                  }}
                </li>
                <li>{{ $t('Work order data and maintenance records') }}</li>
                <li>{{ $t('Asset and equipment information') }}</li>
                <li>{{ $t('Usage data and application interactions') }}</li>
                <li>{{ $t('Communication data through the application') }}</li>
              </ul>
            </section>

            <!-- How We Use Your Information -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('How We Use Your Information') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{ $t('We use the information we collect to:') }}
              </BaseParagraph>
              <ul
                class="list-disc pl-6 mb-4 text-muted-600 dark:text-muted-400 space-y-2"
              >
                <li>
                  {{
                    $t('Provide, operate, and maintain our CMMS application')
                  }}
                </li>
                <li>{{ $t('Improve and personalize your experience') }}</li>
                <li>
                  {{ $t('Process work orders and maintenance requests') }}
                </li>
                <li>{{ $t('Send notifications and updates') }}</li>
                <li>{{ $t('Provide customer support') }}</li>
                <li>
                  {{ $t('Analyze usage patterns and improve our services') }}
                </li>
                <li>{{ $t('Ensure security and prevent fraud') }}</li>
                <li>{{ $t('Comply with legal obligations') }}</li>
              </ul>
            </section>

            <!-- Data Security -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Data Security') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include:',
                  )
                }}
              </BaseParagraph>
              <ul
                class="list-disc pl-6 mb-4 text-muted-600 dark:text-muted-400 space-y-2"
              >
                <li>{{ $t('Encryption of data in transit and at rest') }}</li>
                <li>{{ $t('Regular security assessments and updates') }}</li>
                <li>
                  {{ $t('Access controls and authentication mechanisms') }}
                </li>
                <li>{{ $t('Regular backup procedures') }}</li>
                <li>{{ $t('Employee training on data protection') }}</li>
              </ul>
            </section>

            <!-- Data Sharing -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Data Sharing and Disclosure') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'We do not sell your personal information. We may share your information only in the following circumstances:',
                  )
                }}
              </BaseParagraph>
              <ul
                class="list-disc pl-6 mb-4 text-muted-600 dark:text-muted-400 space-y-2"
              >
                <li>{{ $t('With your consent') }}</li>
                <li>{{ $t('To comply with legal obligations') }}</li>
                <li>
                  {{
                    $t('With service providers who assist in our operations')
                  }}
                </li>
                <li>
                  {{
                    $t(
                      'Within your organization as necessary for business operations',
                    )
                  }}
                </li>
                <li>{{ $t('In case of business transfers or mergers') }}</li>
              </ul>
            </section>

            <!-- Your Rights -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Your Privacy Rights') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{ $t('You have the right to:') }}
              </BaseParagraph>
              <ul
                class="list-disc pl-6 mb-4 text-muted-600 dark:text-muted-400 space-y-2"
              >
                <li>{{ $t('Access and review your personal information') }}</li>
                <li>{{ $t('Request corrections to your data') }}</li>
                <li>{{ $t('Request deletion of your data') }}</li>
                <li>{{ $t('Object to processing of your data') }}</li>
                <li>{{ $t('Request data portability') }}</li>
                <li>{{ $t('Withdraw consent at any time') }}</li>
              </ul>
            </section>

            <!-- Data Retention -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Data Retention') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. Work order and maintenance records may be retained for compliance and historical purposes.',
                  )
                }}
              </BaseParagraph>
            </section>

            <!-- Cookies -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Cookies and Tracking Technologies') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'We use cookies and similar tracking technologies to track activity on our application and store certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
                  )
                }}
              </BaseParagraph>
            </section>

            <!-- Changes to Policy -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Changes to This Privacy Policy') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.',
                  )
                }}
              </BaseParagraph>
            </section>

            <!-- Contact -->
            <section class="mb-8">
              <BaseHeading as="h2" size="xl" weight="semibold" class="mb-4">
                {{ $t('Contact Us') }}
              </BaseHeading>
              <BaseParagraph class="text-muted-600 dark:text-muted-400 mb-4">
                {{
                  $t(
                    'If you have any questions about this Privacy Policy, please contact us:',
                  )
                }}
              </BaseParagraph>
              <ul
                class="list-none pl-0 text-muted-600 dark:text-muted-400 space-y-2"
              >
                <li>{{ $t('Email') }}: sales.ibexllc@gmail.com</li>
                <li>{{ $t('Phone') }}: +976 88087719</li>
              </ul>
            </section>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>
